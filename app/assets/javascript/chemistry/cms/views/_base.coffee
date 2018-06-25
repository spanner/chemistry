# Base classes with useful bits and pieces.
# TODO we are going to need mixins to dry this up very soon.

class Cms.View extends Backbone.Marionette.View
  template: false

  initialize: =>
    @subviews = []

  onRender: =>
    if @model
      @addBinding null, _.result @, 'extraBindings'
      @stickit()
      _.defer =>
        @triggerMethod 'rendered'

  addView: (view) =>
    @subviews.push view

  onDestroy: =>
    if @subviews?.length
      subview.destroy() for subview in @subviews


  ## link helpers
  #
  editMeHref: (id) =>
    id ?= @model.get('id')
    type = @model.label()
    "/#{type}/edit/#{id}"

  showMeHref: (id) =>
    id ?= @model.get('id')
    type = @model.label()
    "/#{type}/show/#{id}"

  pageHref: ([id, content, external_url, file_url]=[]) =>
    @log "pageHref", id, content, external_url, file_url
    if content is 'url'
      external_url
    else if content is 'file'
      file_url
    else
      @editMeHref(id)

  publicPageHref: ([path, content, external_url, file_url]=[]) =>
    @log "publicPageHref", path, content, external_url, file_url
    if content is 'url'
      external_url
    else if content is 'file'
      file_url
    else
      path

  ## onGet helpers
  #
  untrue: (value) =>
    not value

  ifAbsent: (value) =>
    not value

  ifPresent: (value) =>
    not not value

  thisOrThat: ([thing, other_thing]=[]) =>
    thing or other_thing

  thisAndThat: ([thing, other_thing]=[]) =>
    thing and other_thing

  thisButNotThat: ([thing, other_thing]=[]) =>
    thing and not other_thing

  shortAndClean: (value, limit=64) =>
    text = $('<div />').html(value).text().trim()
    if text.length > limit
      shortened = text.substr(0, limit)
      shortened.substr(0, Math.min(shortened.length, shortened.lastIndexOf(" "))) + '…'
    else
      text

  inBytes: (value) =>
    if value
      if value > 1048576
        mb = Math.floor(value / 10485.76) / 100
        "#{mb}MB"
      else
        kb = Math.floor(value / 1024)
        "#{kb}KB"
    else
      ""

  inPixels: (value=0) =>
    "#{value}px"

  inTime: (value=0) =>
    seconds = parseInt(value, 10)
    if seconds >= 3600
      minutes = Math.floor(seconds / 60)
      [Math.floor(minutes / 60), minutes % 60, seconds % 60].join(':')
    else
      [Math.floor(seconds / 60), seconds % 60].join(':')

  asPercentage: (value=0) =>
    "#{value}%"

  providerClass: (provider) =>
    "yt" if provider is "YouTube"

  justDate: (mom) =>
    _amp.log "mom", mom
    mom.format("MMM Do YYYY") if mom

  justDateNoYear: (mom) =>
    mom.format("MMM Do") if mom

  numericalDate: (mom) =>
    mom.format("D/M/YY") if mom

  styleColor: (color) =>
    "color: #{color}" if color

  styleBackgroundColor: (color) =>
    "background-color: #{color}" if color

  styleBackgroundImage: ([url, data]=[]) =>
    url ||= data
    if url
      "background-image: url('#{url}')"
    else 
      ""

  styleBackgroundImageAndPosition: ([url, weighting]=[]) =>
    weighting ?= 'center center'
    "background-image: url('#{url}'); background-position: #{weighting}"

  urlAtSize: (url) =>
    @model.get("#{@_size}_url") ? url

  styleBackgroundAtSize: (url) =>
    if url
      "background-image: url('#{@urlAtSize(url)}')"


  ## Visibility functions
  #
  visibleWithFade: ($el, value) =>
    if value and not $el.is(':visible')
      $el.fadeIn()
    else if $el.is(':visible')
      $el.fadeOut()

  visibleAsBlock: ($el, value) =>
    if value
      $el.css 'display', 'block'
    else
      $el.css 'display', 'none'


  ## Cleanup
  #
  # For saving and publication.
  
  # then onSet we remove all control elements and editable attribuets: 
  # the database holds exactly the html that we will display.
  #
  withoutControls: (html) =>
    @_cleaner ?= $('<div />')
    @_cleaner.html(html)
    @_cleaner.find('[data-cms]').remove()
    @_cleaner.find('[contenteditable]').removeAttr('contenteditable')
    @_cleaner.find('[data-placeholder]').removeAttr('data-placeholder')
    @_cleaner.html()

  withoutHTML: (html) =>
    @_cleaner ?= $('<div />')
    @_cleaner.html(html)
    @_cleaner.text().trim()
  

  ## Utilities
  #
  containEvent: (e) =>
    e?.stopPropagation()
    e?.preventDefault()

  show: =>
    @$el.show()

  hide: =>
    @$el.hide()

  log: ->
    _cms.log "[#{@constructor.name}]", arguments...


class Cms.Views.IndexView extends Cms.View
  regions:
    list: "#chemistry-list"
    notes: "#chemistry-notes"


class Cms.Views.ListedView extends Cms.View
  tagName: "li"

  deleteModelWithConfirmation: (e) =>
    $a = $(e.target)
    confirmation= $a.data('confirmation')
    if !confirmation or confirm(confirmation)
      @log "DESTROY"
      # @model.destroy()


class Cms.EditView extends Cms.View
  ui:
    form: "form"
    submit: 'input[type="submit"]'
    closer: "a.close"
    problems: ".problems"
    warning_sign: "use.warning"

  events:
    "submit form": "saveModel"

  extraBindings: {}

  onRender: =>
    @_saved = false
    @stickit()
    @ui.closer?.attr 'href', @closeHref()

  onBeforeDestroy: =>
    unless @_saved
      @model.revert()


  saveModel: (e) =>
    e?.preventDefault()
    @model.saveAnd =>
      @_saved = true
      _cms.navigate @closeHref()

  saveAndShow: (e) =>
    e?.preventDefault()
    @model.saveAnd =>
      @_saved = true
      _.defer =>
        _cms.log "post-save navigate to", @showMeHref(@model.get('id'))
        _cms.navigate @showMeHref(@model.get('id'))


# The menu view has a head and a toggled body.
# Examples include the image and video pickers.
#
class Cms.Views.MenuView extends Cms.View

  ui:
    head: ".menu-head"
    body: ".menu-body"
    closer: "a.close"

  events:
    "click @ui.head": "toggleMenu"
    "click @ui.closer": "close"

  toggleMenu: (e) =>
    e?.preventDefault()
    if @showing() then @close() else @open()

  showing: =>
    @$el.hasClass('open')

  open: (e) =>
    e?.preventDefault()
    @$el.addClass('open')
    @triggerMethod 'open'
    @trigger 'opened'

  close: (e) =>
    e?.preventDefault()
    @_menu_view?.close()
    @$el.removeClass('open')
    @triggerMethod 'close'
    @trigger 'closed'


## Collection View
#
# Adds some conventional lifecycle and useful bindings to our various composite views:
# map, directory, list of activities at venue or from organisation.

class Cms.CollectionView extends Backbone.Marionette.CollectionView

  initialize: =>
    @render()

  log: ->
    _cms.log "[#{@constructor.name}]", arguments...


class Cms.Views.AttachedCollectionView extends Cms.CollectionView

  initialize: =>
    @collection.loadAnd =>
      @render()


## Composite View
#
# Adds some conventional lifecycle and useful bindings to our various composite views:
# map, directory, list of activities at venue or from organisation.

class Cms.CompositeView extends Backbone.Marionette.CompositeView

  initialize: =>
    @render()

  onRender: =>
    @stickit() if @model

  log: ->
    _cms.log "[#{@constructor.name}]", arguments...


## Chooser views
#
# These are simple collection views with some triggers for selecting an associate.

class Cms.Views.ChoiceView extends Cms.View
  triggers:
    "click a.choose": "choose"


class Cms.Views.NoChoiceView extends Cms.View
  triggers:
    "click a.choose": "clear"


class Cms.Views.ChooserView extends Cms.CollectionView

  onChildviewChoose: (view, e) =>
    @choose view.model
    view.model.markAsChosen()

  choose: (model) =>
    #noop here



## Collection select
#
# Is a general purpose way of populating a select box with a collection,
# usually in order to select an associate.
#
class Cms.Views.ModelOption extends Cms.View
  template: false
  tagName: "option"

  bindings:
    ":el":
      observe: "title"
      onGet: "titleOrDefault"
      updateMethod: "html"
      attributes: [
        name: "value"
        observe: "id"
      ,
        name: "disabled"
        observe: "title"
        onGet: "isBlank"
      ]

  initialize: (options={}) ->
    @_attribute = @getOption 'attribute'
    @_selecting_model = @getOption 'selecting'
    if @_attribute and @_selecting_model
      @addBinding @_selecting_model, ":el",
        attributes: [
          observe: @_attribute
          name: "selected"
          onGet: "isSelected"
        ]

  titleOrDefault: (title) =>
    title or "Please select"

  isSelected: (value) =>
    'selected' if value?.id is @model.id

  isBlank: (name) =>
    !name


class Cms.Views.CollectionSelect extends Cms.CollectionView
  template: false
  tagName: "select"
  childView: Cms.Views.ModelOption

  events:
    "change": "setSelection"

  initialize: () ->
    @_attribute = @getOption 'attribute'
    @_allow_blank = @getOption 'allowBlank'
    @log "init", @_attribute, @collection
    @collection = @collection.clone()
    @collection.add({}, {at: 0}) if @_allow_blank
    super

  onReady: =>
    @collection.whenLoaded =>
      @setSelection() unless @model.get(@_attribute)

  childViewOptions: (other_model) =>
    selecting: @model
    attribute: @_attribute

  setSelection: (e) =>
    @log "setSelection", @$el.val()
    if selection_id = @$el.val()
      @log "setSelection", @_attribute, ' ->', selection_id, @collection.get(selection_id)
      @model.set @_attribute, @collection.get(selection_id)
    else if @_allow_blank
      @log "unsetSelection", @_attribute
      @model.set @_attribute, null


