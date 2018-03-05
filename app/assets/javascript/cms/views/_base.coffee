# Base classes with useful bits and pieces.
# TODO we are going to need mixins to dry this up very soon.

class Cms.View extends Backbone.Marionette.View
  template: false

  initialize: =>
    @subviews = []
    @render()

  onRender: =>
    @log "render"
    @stickit() if @model

  addView: (view) =>
    @subviews.push view
    view.render()

  onDestroy: =>
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

  blank: (value) =>
    not value?.trim()

  present: (value) =>
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


class Cms.IndexView extends Cms.View
  regions:
    list: "#chemistry-list"
    notes: "#chemistry-notes"


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
    @log "CHOOSE!", view
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
    @$el.addClass 'up'
    view.on "close", =>
      @log "FloatingRegion close trigger"
      @$el.on 'transitionend', @reset
      @$el.removeClass 'up'

  log: ->
    _cms.log "[#{@constructor.name}]", arguments...


class Cms.Views.FloatingView extends Cms.View

  triggers:
    "click a.close": "close"
    "click a.cancel": "close"
