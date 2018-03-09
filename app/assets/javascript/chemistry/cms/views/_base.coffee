# Base classes with useful bits and pieces.
# TODO we are going to need mixins to dry this up very soon.

class Cms.View extends Backbone.Marionette.View
  template: false

  initialize: =>
    @subviews = []
    @render()

  onRender: =>
    @stickit() if @model

  addView: (view) =>
    @subviews.push view
    view.render()

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


  ## onGet helpers
  #
  untrue: (value) =>
    not value

  ifAbsent: (value) =>
    not value

  ifPresent: (value) =>
    not not value

  thisAndThat: ([thing, other_thing]=[]) =>
    thing and other_thing

  thisButNotThat: ([thing, other_thing]=[]) =>
    thing and not other_thing

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

  styleBackgroundImage: (url) =>
    "background-image: url('#{url}')"

  styleBackgroundImageAndPosition: ([url, weighting]=[]) =>
    weighting ?= 'center center'
    "background-image: url('#{url}'); background-position: #{weighting}"


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


## Collection View
#
# Adds some conventional lifecycle and useful bindings to our various composite views:
# map, directory, list of activities at venue or from organisation.

class Cms.CollectionView extends Backbone.Marionette.CollectionView

  initialize: =>
    @render()

  log: ->
    _cms.log "[#{@constructor.name}]", arguments...


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


## Floating overlays
#  are handled by a custom region class that does the floating part.
#
class Cms.FloatingRegion extends Backbone.Marionette.Region

  onShow: (region, view, options={}) =>
    @log "FloatingRegion onShow", options
    if $over = options.over
      offset = $over.offset()
      default_adjustment =
        top: -20
        left: -20
      offset_offset = options.offset or default_adjustment
      @$el.css
        top: offset.top + offset_offset.top
        left: offset.left + offset_offset.left
    view.on 'close', => @reset()
    @$el.addClass 'up'

  removeView: (view) =>
    @log "FloatingRegion removeView"
    @$el.removeClass 'up'
    _.delay =>
      @destroyView view
    , 500

  log: ->
    _cms.log "[#{@constructor.name}]", arguments...


class Cms.Views.FloatingView extends Cms.View

  triggers:
    "click a.close": "close"
    "click a.cancel": "close"



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


