class Cms.Collection extends Backbone.Collection
  criteria: null
  default_sort: 'date'
  date_attribute: 'created_at'
  name_attribute: 'title'

  getOption: (optionName) =>
    if optionName
      @options?[optionName] ? @[optionName]

  initialize: (models, @options={}) ->
    @_class_name = @constructor.name
    @_nested = @options.nested    # normally only set by hasMany
    @setOriginalIds()
    @prepareLoader()
    @setDefaults()
    @on 'add remove reset', @setDefaults
    @debouncedReload = _.debounce @reload, 250

    if @getOption('paginated')
      @_paginated = true
      @initPagination opts.params
    else
      @_paginated = false

    if @getOption('sorted')
      @_sorted = true
      @initSorting opts.params
    else
      @_sorted = false

  setDefaults: =>
    # noop here

  setParams: (params) =>
    @setPaginationState(params) if @_paginated
    @setSortState(params) if @_sorted


  ## Sorting
  #
  # Default sort `attributes` are defined here.
  # Current sort `state` is held in the @_sorter model for binding in the UI.
  # NB @_sorter holds abstract values like 'date' or 'name'; each collection
  # will turn that into a sort by the most salient model attribute.
  # The collection would usually do that by redefining over these defaults:
  #
  #   default_sort: 'date'
  #   date_attribute: 'created_at'
  #   name_attribute: 'title'
  #   name_localised: true
  #
  initSorting: (params={}) =>
    @_default_sort = _.result(@, 'default_sort')
    @_date_attribute = _.result(@, 'date_attribute')
    @_name_attribute = _.result(@, 'name_attribute')
    if @_sorted
      @_sorter = new Cms.Models.Sorter
      @setSortState(params)
      @_sorter.on 'change', @debouncedReload

  getSorter: =>
    @_sorter

  # Prepare sort parameters for the API
  #
  sortParams: =>
    if @_sorted
      params =
        order: @_sorter.get('sort_order')
        sort: if @_sorter.get('sort_by') is 'date' then @_date_attribute else @_name_attribute
      params
    else
      {}

  setSortState: (params={}) =>
    attributes = {}
    attributes.sort_by = params.s || @_default_sort
    attributes.sort_order = params.o || @_sorter.defaultOrderFor(attributes.sort_by)
    @_sorter.set attributes

  # This is the default comparator to support sorted pagination of normal objects in normal lists.
  # Subclasses may choose to override to sort differently
  # eg. if all data is already present or if sorting is not required.
  #
  comparator: (this_model, that_model) ->
    if @_sorter?.get('sort_by') is 'date'
      this_date = moment(this_model.get(@_date_attribute)) || moment()
      that_date = moment(that_model.get(@_date_attribute)) || moment()
      difference = Math.round(this_date.diff(that_date))
      direction = Math.sign(difference)
    else
      this_name = this_model.get(@_name_attribute) || ""
      that_name = that_model.get(@_name_attribute) || ""
      direction = this_name.localeCompare(that_name, 'en')  #TODO: come back when localising
    if @_sorter?.get('sort_order') is 'desc'
      -direction
    else
      direction


  ## Pagination
  #
  # is specified by query string arguments, passed through the UI and/or collection view 
  # and translated here into fetch parameters.
  #
  initPagination: (params={}) =>
    @_page = params.p ? 1
    @_per_page = params.pp ? 20
    @_q = params.q

  # Provide the pagination view with all the information it will need.
  # TODO: bindable @_paginator object like the sorter?
  #
  getPaginationState: =>
    first_visible_record = @_page_size * (@_page - 1) + 1
    last_visible_record = @_page_size * @_page
    last_visible_record = @_total_records if @_total_records < last_visible_record 
    state =
      page: @_page
      per_page: @_page_size
      total_records: @_total_records
      first_record: first_visible_record
      last_record: last_visible_record
      first_page: 1
      last_page: @_total_pages
    state.next_page = @_page + 1 if @_page < @_total_pages
    state.prev_page = @_page - 1 if @_page > 1
    state

  isPaginated: =>
    @_paginated

  # Called from the UI view during page construction to pass through pagination parameters.
  #
  setPaginationState: (params={}) =>
    @_page = params.p
    @_per_page = params.pp
    @_q = params.q
    @debouncedReload()

  # Prepare onward pagination parameters for the API
  #
  paginationParams: =>
    params = {}
    if @_paginated
      params.page = @_page if @_page
      params.per_page = @_per_page if @_per_page
    params


  ## Searching
  #
  setFilter: (term) =>
    unless @_q is term
      @_q = term
      @debouncedReload()

  getFilter: () =>
    @_q


  ## Loading
  #
  # The collection has a load promise too, that will be resolved when it is fetched directly
  # or bulk-populated through a hasMany link.
  #
  prepareLoader: =>
    @_loaded?.reject()
    @_loaded = $.Deferred()
    @_loading = false

  url: =>
    base = @baseUrl()
    if params = @urlParams()
      base += "?" + params
    base

  baseUrl: () =>
    if @_nested
      [_cms.config('api_url'), @_nested.pluralName(), @_nested.id, @pluralName()].join('/')
    else
      [_cms.config('api_url'), @pluralName()].join('/')

  urlParams: =>
    params = _.result(@, 'criteria') or {}
    params = _.extend params, @sortParams(), @paginationParams()
    params.q = @_q if @_q
    $.param(params)

  load: =>
    unless @_loading or @isLoaded()
      @_loading = true
      @fetch(reset: true).done(@loaded).fail(@notLoaded)
    @_loaded.promise()

  reload: =>
    @prepareLoader()
    @load()

  parse: (response) =>
    if @prepareData(response)
      response.data

  prepareData: (response) =>
    # noop here. Return false to stop parsing.
    true

  loaded: (data, status, xhr) =>
    if xhr
      if @_paginated
        # TODO look at jsonapi metadata instead
        @_page_size = parseInt(xhr.getResponseHeader("X-Per-Page"), 10)
        @_page = parseInt(xhr.getResponseHeader("X-Page"), 10)
        @_total_records = parseInt(xhr.getResponseHeader("X-Total"), 10)
        @_total_pages = Math.ceil(@_total_records / @_page_size)
    @_loading = false
    @sort()
    @setOriginalIds()
    @_loaded?.resolve(data)
    @trigger('loaded')

  whenLoaded: (dothis) =>
    @_loaded.done(dothis)

  whenLoadedOrFailed: (dothis) =>
    @_loaded.always(dothis)

  loadAnd: (dothis) =>
    @whenLoaded(dothis)
    @load()

  reloadAnd: (dothis) =>
    @whenLoaded(dothis)
    @reload()

  isLoaded: =>
    @_loaded?.state() is 'resolved'

  notLoaded: (error) =>
    @_loaded.reject(error)


  ## Change management
  
  hasAnyChanges: =>
    @hasCollectionChanges() or @hasModelChanges()

  hasCollectionChanges: =>
    !_.isEqual @pluck('id'), @_original_ids

  hasModelChanges: =>
    !!@findWhere changed: true

  setOriginalIds: =>
    @_original_ids = @pluck('id')

  resetChanges: =>
    @setOriginalIds()
    @each (m) -> m.resetChanges()


  ## Selection

  resetChoices: =>
    @each (model) ->
      model.set 'chosen', false


  # Structural

  className: =>
    @_class_name

  singularName: =>
    name = _.singularize @pluralName()

  pluralName: =>
    s.underscored @className()


  ## Useful
  #
  findOrAdd: (attributes) =>
    unless model = @findWhere(attributes)
      model = @add(attributes)
      model.loadIfBare()
    model

  setAll: (k, v) =>
    @each (m) -> m.set k, v

  toJSONWithAssociations: (options) =>
    @map (model) -> 
      model.toJSONWithAssociations(options)

  log: ->
    _cms.log "[#{@constructor.name}]", arguments...
