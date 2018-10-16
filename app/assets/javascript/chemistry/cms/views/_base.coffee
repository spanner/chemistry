# Base classes with useful bits and pieces.
#
class Cms.View extends Marionette.View
  template: ""

  initialize: =>
    @subviews = []

  onRender: =>
    if @model
      @addBinding null, _.result @, 'extraBindings'
      @stickit()
      @triggerMethod 'ready'

  addView: (view) =>
    @subviews.push view
    view.on "update", @onUpdate
    view.render()

  onDestroy: =>
    if @subviews?.length
      subview.destroy() for subview in @subviews

  onUpdate: =>
    @log "🚜 base onUpdate"
    # noop here but a view may want to attend to a subview


  ## link helpers
  #
  editMeHref: (id) =>
    id ?= @model.get('id')
    type = _cms.pluralize @model.label()
    "/#{type}/edit/#{id}"

  showMeHref: (id) =>
    id ?= @model.get('id')
    type = _cms.pluralize @model.label()
    "/#{type}/show/#{id}"

  pageHref: ([id, content, external_url, file_url]=[]) =>
    if content is 'url'
      external_url
    else if content is 'file'
      file_url
    else if content is 'empty'
      ''
    else
      @editMeHref(id)

  publicPageHref: ([path, content, external_url, file_url]=[]) =>
    if content is 'url'
      external_url
    else if content is 'file'
      file_url
    else if content is 'empty'
      ''
    else
      path

  mailtoHref: (email) =>
    "mailto:#{email}"

  absolutePath: (path) =>
    if path
      if path[0] is '/' then path else "/#{path}"


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

  thatIfThis: ([flag, value]=[]) =>
    value if flag

  thatIfThisIsVideo: ([flag, value]=[]) =>
    value if flag is 'video'

  thatIfThisIsImage: ([flag, value]=[]) =>
    value if flag is 'image'

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

  niceDatetime: (mom) =>
    now = moment()
    if mom.isSame(now, 'day')
      mom.format t('date_formats.time_today')
    else if mom.isSame(now, 'month')
      mom.format t('date_formats.this_month')
    else if mom.isSame(now, 'year')
      mom.format t('date_formats.this_year')
    else
      mom.format t('date_formats.time_on_date')

  publicationDate: ([date, publication_date]=[]) =>
    date or= publication_date
    date.format("LL") if date

  justDate: (mom) =>
    mom.format("MMM Do YYYY") if mom

  justDateNoYear: (mom) =>
    mom.format("MMM Do") if mom

  numericalDate: (mom) =>
    mom.format("D/M/YY") if mom

  videoId: (id) =>
    "video_#{id}"

  imageId: (id) =>
    "image_#{id}"

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


  ## Save and publish
  #
  # Object is saveable if it is valid and has significant changes.
  #
  unSaveable: ([changed, valid]=[]) =>
    !changed or !valid

  # Object is revertable if it has significant changes.
  #
  unRevertable: (changed) =>
    !changed

  # Object is reviewable if it has ever been published.
  #
  unReviewable: (unpublished) =>
    !!unpublished

  # page is publishable if it has any content and no unsaved changes,
  # and the current publication is out of date.
  #
  unPublishable: ([content, empty, changed, valid, outofdate]=[]) =>
    changed or empty or !valid or !outofdate or content is 'empty'

  save: (e) =>
    e?.preventDefault()
    @model.save()

  revert: (e) =>
    e?.preventDefault()
    @model.revert()

  revertWithConfirmation: (e) =>
    e?.preventDefault()
    new Cms.Views.ReversionConfirmation
      model: @model
      link: @ui.revert_button
      action: @revert

  publish: =>
    e?.preventDefault()
    @model.publish()

  publishWithConfirmation: (e) =>
    e?.preventDefault()
    new Cms.Views.PublicationConfirmation
      model: @model
      link: @ui.publish_button
      action: @publish


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
    @_cleaner.find('[contenteditable]').removeAttr('contenteditable')
    @_cleaner.find('[data-cms]').remove()
    @_cleaner.find('[data-placeholder]').removeAttr('data-placeholder')
    @_cleaner.find('[data-cms-role]').removeAttr('data-cms-role')
    @_cleaner.find('[data-cms-editor]').removeAttr('data-cms-editor')
    @_cleaner.find('[data-asset-id]').removeAttr('data-asset-id')
    @_cleaner.find('[data-asset-type]').removeAttr('data-asset-type')
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


class Cms.ItemView extends Cms.View
  onRender: =>
    if @model
      @addBinding null, _.result @, 'extraBindings'
      @model.loadAnd =>
        @stickit()
        @triggerMethod 'ready'


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
    @place()
    @$el.addClass('open')
    @log "🍄 open", @$el
    @triggerMethod 'open'
    @trigger 'opened'

  close: (e) =>
    e?.preventDefault()
    @_menu_view?.close()
    @$el.removeClass('open')
    @triggerMethod 'close'
    @trigger 'closed'

  # ideally we want to put the X over the menu head for quick toggling
  # but that pushes the menu offscreen, we'll align to its other side.
  place: =>
    position = @ui.head.position()
    bw = @ui.body.width()
    hw = @ui.head.width()
    bh = @ui.body.height()
    hh = @ui.head.height()
    left = position.left + hw + 11 - bw
    top = position.top - 9
    if left < 0
      left = position.left - 11
    if top + bw > document.body.scrollHeight
      top = position.top + hh + 9 - bh
    @ui.body.css
      top: top
      left: left


## Collection View
#
# Adds some conventional lifecycle and useful bindings to our various composite views:
# map, directory, list of activities at venue or from organisation.

class Cms.CollectionView extends Marionette.CollectionView

  log: ->
    _cms.log "[#{@constructor.name}]", arguments...


class Cms.Views.AttachedCollectionView extends Cms.CollectionView

  initialize: =>
    @collection.loadAnd =>
      @render()


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

  childViewEvents:
    choose: "chooseChild"

  chooseChild: (view, e) =>
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
  template: ""
  tagName: "option"

  bindings:
    ":el":
      observe: "title"
      onGet: "titleOrDefault"
      updateMethod: "html"
      attributes: [
        name: "value"
        observe: "id"
      ]

  initialize: (opts={}) ->
    super
    @_selected = !!opts.selected

  onRender: =>
    @stickit()
    if @_selected
      @$el.attr 'selected', "selected"

  titleOrDefault: (title) =>
    title or ""


class Cms.Views.CollectionSelect extends Cms.CollectionView
  template: ""
  tagName: "select"
  childView: Cms.Views.ModelOption

  events:
    "change": "setSelection"

  initialize: ->
    super
    @_attribute = @getOption 'attribute'
    @_allow_blank = @getOption 'allow_blank'

  onRender: =>
    if @_allow_blank
      blank_option = $('<option value=""><option>')
      @$el.prepend blank_option

  childViewOptions: (model) =>
    {
      model: model
      selected: model is @model.get(@_attribute)
    }

  setSelection: (e) =>
    @log "setSelection", @$el.val()
    if selection_id = @$el.val()
      @log "setSelection", @_attribute, ' ->', selection_id, @collection.get(selection_id)
      @model.set @_attribute, @collection.get(selection_id)
    else if @_allow_blank
      @log "unsetSelection", @_attribute
      @model.set @_attribute, null


