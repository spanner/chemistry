# Model lifecycle:
#
# 1. init sets up a promise of readiness
# 2. build sets up attributes and collections
# 3. load fetches data from the API
# 4. loaded resolves the promise, which triggers populate
# 5. populate places received data into attributes and collections
# 6. save
#
# Call `model.ready()` to access the readiness promise after construction
# or call `whenLoaded(function)` to attach more callbacks. They will
# fire after population and receive the fetched data as first argument.
#
class Cms.Model extends Backbone.Model
  autoload: false
  savedAttributes: []
  savedAssociations: []
  uploadProgress: false

  initialize: (opts={}) ->
    @_class_name = @constructor.name
    @_original_attributes = {}
    @checkState = _.debounce @changedIfSignificantlyChanged, 250

    @prepareLoader()
    @load() if @autoload

    ## Build
    # is a preparatory step that usually sets up hasMany collections and belongsTo associations.
    #
    @build()

    ## Saving
    #
    # every model carries a 'changed' marker and on every significant change we check present attributes against
    # original attributes and set the 'changed' marker accordingly.
    #
    @prepareSaver()
    @recordAttributes()
    @set 'changed', false
    @on "change", @checkState
    @on "change", @validate


  ## Useful
  #
  # SetDefault sets an attribute if it is not set, as though it always had been set.
  # This is useful for eg. assigning a page title to the first section without setting off all the save buttons.
  #
  setDefault: (attribute, value) =>
    @set(attribute, value) unless @get(attribute)
    @defaults[attribute] = value
    @_original_attributes[attribute] = value


  ## Load
  # Loading is promised. Actions that should be taken only when a model needs no further fetching
  # can be triggered safely with `model.loadAnd(function)` or `model.whenLoaded(function)`,
  # which does not itself trigger loading but will call back when loading is complete.
  # The loaded promise is resolved when we are fetched either individually or in a collection.
  #
  urlRoot: () =>
    if @collection
      @collection.url()
    else
      [_cms.config('api_url'), @pluralName()].join('/')

  prepareLoader: =>
    @_loader?.cancel()
    @_loaded = $.Deferred()
    @_loaded.resolve() if @isNew()
    @_loading = false

  loadAnd: (fn) =>
    @_loaded.done fn
    @load()

  whenLoaded: (fn) =>
    @_loaded.done fn

  whenFailed: (fn) =>
    @_loaded.fail fn

  isLoaded: =>
    @_loaded.state() is 'resolved'

  load: =>
    unless @_loading or @isLoaded()
      @_loading = true
      @_loader = @fetch(error: @notLoaded).done(@loaded)
    @_loaded.promise()

  loaded: (data) =>
    @_loading = false
    @_loader = null
    @_saved.resolve()
    @_loaded.resolve(data)
    @resetChanges()

  notLoaded: (error) =>
    @_loading = false
    @_loader = null
    @_loaded.reject(error)

  reload: ->
    @prepareLoader()
    @load()

  loadIfBare: =>
    @load() if @isBare()

  # true if we have _only_ an idAttribute, which would mean we are meant to be fetched.
  isBare: =>
    bare_attributes = {}
    bare_attributes[@idAttribute] = @get(@idAttribute)
    _.isEqual @attributes, bare_attributes


  ## Saving
  # Here we override save to wrap a promise around it and attach callbacks.
  # In application.js we also override sync to add progress handlers.
  #

  prepareSaver: =>
    @_saved = $.Deferred()
    @_saved.resolve() unless @isNew()
    @_saving = false

  save: =>
    unless @_saving
      @_saved = $.Deferred()
      @_saving = true
      saver = super
      saver.fail(@notSaved).done(@saved)
    @_saved.promise()

  saved: (data) =>
    @_saving = false
    @_saved.resolve(data)
    @confirmSave()
    @resetChanges()
    # @reloadAssociations()

  confirmSave: =>
    @confirm t('reassurances.saved')

  notSaved: (error) =>
    @_saving = false
    @_saved.reject(error)

  revert: =>
    @reload()


  ## Upload progress
  # Callbacks that capture progress values for display purposes.
  # This is called from a `beforeSend` hook in sync.
  #
  isProgressive: =>
    _.result @, 'uploadProgress'

  startProgress: () =>
    @_job = _cms.addJob()
    @_job.setStatus('Saving')
    @set "progressing", true

  setProgress: (p) =>
    @_job?.setProgress(p)

  finishProgress: () =>
    @_job?.finish()
    @_job?.discard()
    @set "progressing", false

  failProgress: (error) =>
    @_job?.fail(error)


  ## Construction
  #
  build: =>
    # usually this is where we set up associates:
    # @hasMany 'sections'
    # @belongsTo 'image'
    # etc

  parse: (response) =>
    #TODO: be less fucked up
    attributes = response.attributes or response.data?.attributes
    if @populate(attributes)
      attributes

  populate: (attributes) =>
    # @things.reset(data.things)
    @momentify(attributes)
    true

  momentify: (data) =>
    for col in ["created_at", "updated_at", "published_at", "deleted_at", "date", "to_date"]
      if string = data[col]
        data[col] = moment(string)


  ## Associations
  #
  # belongsTo sets up the listeners involved in maintaining a one-to-one association.
  # It allows us to fetch and save an object_id while working in the UI with the instantiated object.
  # The object has to be gettable from the supplied collection using the object_id.
  #
  # The UI and any view bindings should always use the object_attribute
  # (eg set or bind to 'video', not 'video_id').
  # The id_attribute is only for use upwards, to and from the API.
  #
  belongsTo: (object_attribute, collection) =>
    if object_attribute is 'parent'
      model_class_name = @className()
    else
      model_class_name = _.titleize(_.camelize(object_attribute))
    model_class = Cms.Models[model_class_name]
    collection ?= _cms[model_class_name.toLowerCase() + 's']

    # For the usual situation when an associate is sent down just as eg. section_type_id
    id_attribute = "#{object_attribute}_id"
    if object_id = @get(id_attribute)
      if collection
        unless foreign_object = collection.get(object_id)
          console.error "Association error: #{@className()} #{@id} can find no #{object_attribute} for id #{object_id}"
        @set object_attribute, foreign_object, silent: true
      else
        new_object = new model_class({id: object_id})
        @set object_attribute, new_object

    # For the unusual case where a whole nested object is sent down.
    else if object_data = @get(object_attribute)
      object = new model_class(object_data)
      @set object_attribute, object, silent: true
      @set id_attribute, object.get('id'), silent: true

    # In the UI we always assign the object
    @on "change:#{object_attribute}", (me, it, options) =>
      if it
        # something has been assigned
        if id = it.get('id')
          # ...that already exists and has an ID.
          @set id_attribute, id, stickitChange: true
        else
          # ...that is new and ought to get an ID soon.
          it.once "change:id", (it_again, new_id) =>
            @set id_attribute, new_id, stickitChange: true
      else
        # `nothing` has been assigned
        @set id_attribute, null, stickitChange: true


  # hasMany sets up the listeners involved in maintaining a one to many association
  # and provides all the logic of receiving and saving nested collection data.
  #
  # In the UI we should always use the attached collection.
  # On load and save it is a nested list of attribute hashes.
  #
  hasMany: (association_name, options={}) =>
    class_name = options.collection_class ? _.capitalize(s.camelize(association_name))
    collection_class = Cms.Collections[class_name]

    # create collection from the initial association data
    default_collection_options =
      paginated: false
      nested: this
    @[association_name] = new collection_class null, _.extend(default_collection_options, options)

    # Listen for changes to the association data and repopulate the attached collection
    @on "change:#{association_name}", (model, data) =>
      data ?= @get(association_name) || []
      @[association_name].set data,
        add: true
        remove: true
        merge: true
        reset: true
      @set association_name, null, silent: true

    # Trigger the change mechanism to initialize the attached collection with the initial association data
    @trigger "change:#{association_name}"

    # Listen for changes to the attached collection.
    @[association_name].on "change:changed add remove clear reset", (e) =>
      @changedIfSignificantlyChanged()

  toJSONWithRootAndAssociations: =>
    root = @singularName()
    json = {}
    json[root] = @toJSONWithAssociations()
    json

  toJSONWithAssociations: =>
    json = {}
    if attributes = _.result @, "savedAttributes"
      for att in attributes
        json[att] = @get(att)
    else
      json = @toJSON()
    if associations = _.result @, "savedAssociations"
      for association_name in associations
        json["#{association_name}_data"] = @[association_name].toJSONWithAssociations()
    json


  ## Contenteditable helpers
  #
  # Small interventions to make contenteditable behave in a slightly saner way,
  # eg. by definitely typing into an (apparently) empty <p> element.
  #
  ensureP: (e) =>
    el = e.target
    @log '🎺 ensureP', el, el.innerHTML
    if el.innerHTML.trim() is ""
      el.style.minHeight = el.offsetHeight + 'px'
      p = document.createElement('p')
      el.appendChild p
      if ( document.selection and document.body.createTextRange)
        range = document.body.createTextRange()
        range.setStart(p, 0)
        range.select()


  clearP: (e) =>
    el = e.target
    content = el.innerText.trim()
    @log '🎺 clearP', el, content
    el.innerHTML = "" unless content


  ## Change monitoring
  #
  changedIfSignificantlyChanged: =>
    @set "changed", @hasSignificantChangedAttributes() or @hasSignificantChangedAssociations()

  recordAttributes: =>
    @_original_attributes = @significantAttributes()

  resetChanges: =>
    _.each @savedAssociations, (k) =>
      @[k].resetChanges()
    @recordAttributes()
    @changedIfSignificantlyChanged()

  significantAttributes: => 
    _.pick @attributes, @savedAttributes

  hasSignificantChangedAttributes: () =>
    not _.isEmpty @significantChangedAttributes()

  significantChangedAttributes: () =>
    current_attributes = @significantAttributes()
    changed_keys = _.filter _.keys(current_attributes), (k) =>
      current_attributes[k] isnt @_original_attributes[k]
    _.pick current_attributes, changed_keys

  hasSignificantChangedAssociations: () =>
    not _.isEmpty @significantChangedAssociations()

  significantChangedAssociations: () =>
    _.filter @savedAssociations, (k) => @[k].hasAnyChanges()

  # TODO unpack jasonapi properly, then serialise associations. 
  reloadAssociations: =>
    _.each @savedAssociations, (k) => @[k].debouncedReload()

  ## Validation
  #
  validate: =>
    @set 'valid', true
    return null


  ## Selection

  markAsChosen: =>
    @collection?.resetChoices()
    @set 'chosen', true


  ## Structural
  #
  className: =>
    @_class_name

  label: =>
    @_class_name.toLowerCase()

  singularName: =>
    _.underscored @className()

  pluralName: =>
    _cms.pluralize @singularName()

  isA: (class_name) =>
    @_class_name is class_name


  ## Housekeeping
  #
  touch: () =>
    @set 'updated_at', moment(),
      stickitChange: true

  isDestroyed: () =>
    @get('deleted_at')

  sig: ->
    "#{@constructor.name} • #{@cid}"

  log: ->
    _cms.log "[#{@sig()}]", arguments...

  confirm: ->
    _cms.confirm arguments...

  complain: ->
    _cms.complain arguments...


