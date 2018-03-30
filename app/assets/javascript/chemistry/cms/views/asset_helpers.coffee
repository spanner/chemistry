## Asset inserter
#
# This view inserts a new asset element into the html stream with a management view wrapped around it.
#
class Cms.Views.AssetInserter extends Cms.View
  template: "assets/inserter"
  tagName: "div"
  className: "cms-inserter"

  events:
    "click a.show": "toggleButtons"
    "click a.image": "addImage"
    "click a.video": "addVideo"
    "click a.quote": "addQuote"
    "click a.annotation": "addAnnotation"

  initialize: (@options={}) ->
    @log "init", @options
    @_target_el = @options.target
    @_p = null

  onRender: () =>
    @log "onRender"
    @$el.appendTo _cms.el
    @_target_el.on "click keyup focus", @followCaret

  followCaret: (e)=>
    @log "followCaret"
    selection = @el.ownerDocument.getSelection()
    if !selection or selection.rangeCount is 0
      current = $(e.target)
    else
      range = selection.getRangeAt(0)
      current = $(range.commonAncestorContainer)
    @_p = current.closest('p')
    text = @_p.text()
    if @_p.length and _.isBlank(text) or text is "​" # zwsp!
      @log "showing", @el
      @show(@_p)
    else
      @log "not showing:", @_p.text().length
      @hide()

  toggleButtons: (e) =>
    e?.preventDefault()
    if @$el.hasClass('showing')
      @trigger 'contract'
      @$el.removeClass('showing')
    else
      @trigger 'expand'
      @$el.addClass('showing')

  addImage: (e) =>
    e?.preventDefault()
    @insert new Cms.Views.Image

  addVideo: (e) =>
    e?.preventDefault()
    @insert new Cms.Views.Video

  addQuote: (e) =>
    e?.preventDefault()
    @insert new Cms.Views.Quote

  addAnnotation: (e) =>
    e?.preventDefault()
    @insert new Cms.Views.Annotation

  insert: (view) =>
    if @_p
      @_p.before view.el
      @_p.remove() unless @_p.is(":last-child")
    else
      @_target_el.append view.el
      @_target_el.append $("<p />")
    view.render()
    view.focus?()
    # @_target_el.trigger 'input'
    @hide()

  place: ($el) =>
    position = $el.offset()
    @$el.css
      top: position.top - 6
      left: position.left - 40

  show: () =>
    @place(@_p)
    @$el.show()

  hide: () =>
    @$el.hide()
    @$el.removeClass('showing')


## Asset stylers
#
# All the assets get similar layout options,
# depending on which buttons are provided in that template of that subclass.

class Cms.Views.AssetStyler extends Cms.View
  tagName: "div"
  className: "styler"
  template: "assets/styler"
  events:
    "click a.right": "setRight"
    "click a.left": "setLeft"
    "click a.full": "setFull"
    "click a.wide": "setWide"
    "click a.hero": "setHero"

  onRender: =>
    if @model
      @$el.show()
    else
      @$el.hide()

  setModel: (model) =>
    @model = model
    @render()

  setRight: => @trigger "styled", "right"
  setLeft: => @trigger "styled", "left"
  setFull: => @trigger "styled", "full"
  setWide: => @trigger "styled", "wide"


## Asset-choosers
#
# The submenu for each asset picker is a chooser-list derived from this class.
# Most are small thumbnail galleries with add and import controls alongside.
#
class Cms.Views.ListedAsset extends Cms.View
  template: "assets/listed"
  tagName: "li"
  className: "asset"

  ui:
    img: 'img'

  events:
    "click a.delete": "deleteModel"
    "click a.preview": "selectMe"

  bindings:
    "a.preview":
      attributes: [
        name: 'style'
        observe: 'thumb_url'
        onGet: "backgroundUrl"
      ,
        name: "class"
        observe: "provider"
        onGet: "providerClass"
      ,
        name: "title"
        observe: "title"
      ]
    ".file_size":
      observe: "file_size"
      onGet: "inBytes"
    ".width":
      observe: "width"
      onGet: "inPixels"
    ".height":
      observe: "height"
      onGet: "inPixels"
    ".duration":
      observe: "duration"
      onGet: "inTime"

  deleteModel: (e) =>
    e?.preventDefault()
    @model.remove()

  selectMe: (e) =>
    e?.preventDefault?()
    @trigger 'select', @model

  backgroundUrl: (url) =>
    if url
      "background-image: url('#{url}')"
    else
      ""


class Cms.Views.NoListedAsset extends Cms.View
  template: "assets/no_asset"
  tagName: "li"
  className: "empty"


class Cms.Views.AssetsList extends Cms.CompositeView
  template: "assets/list"
  childViewContainer: "ul.cms-assets"
  childView: Cms.Views.ListedAsset
  emptyView: Cms.Views.NoListedAsset

  events:
    "click a.import": "importAsset"
    "click a.next": "nextPage"
    "click a.prev": "prevPage"

  childViewEvents:
    'select': 'select'

  ui:
    'heading': 'span.heading'
    'import_field': 'input.remote_url'
    'import_button': 'a.import'

  initialize: (opts={}) =>
    @_title = opts.title ? "Assets"

  onRender: =>
    @ui.heading.text @_title

  # passed through to the picker.
  #
  select: (model) =>
    @trigger 'select', model

  open: =>
    @$el.slideDown 'fast'

  close: =>
    @$el.slideUp 'fast'

  closeAndRemove: (callback) =>
    @$el.slideUp 'fast', =>
      @remove()
      callback?()

  importAsset: =>
    if remote_url = @ui.import_field.val()
      @ui.import_button.addClass('waiting')
      imported = @collection.add
        remote_url: remote_url
      importCms.save().done =>
        @ui.import_button.removeClass('waiting')
        @ui.import_field.val("")
        @trigger 'selected', imported


## Asset-pickers
#
# These menus are embedded in the asset view. They select from an asset collection to
# set the model in the asset view, with the option to upload or import new items.
#
class Cms.Views.AssetPicker extends Cms.Views.MenuView
  tagName: "div"
  className: "picker"
  menuView: "AssetsList"

  ui:
    head: ".menu-head"
    body: ".menu-body"
    label: "label"
    filefield: 'input[type="file"]'

  events:
    "click @ui.head": "toggleMenu"
    "click @ui.filefield": "containEvent" # always artificial

  onRender: =>
    @ui.label.on "click", @close
    @ui.filefield.on 'change', @getPickedFile

  open: =>
    @ui.body.show()
    unless @_menu_view
      menu_view_class = @getOption('menuView')
      @_menu_view = new Cms.Views[menu_view_class]
        collection: @collection
      @ui.body.append @_menu_view.el
      @_menu_view.render()
      @_menu_view.on "select", @select
    @collection.reload()
    @_menu_view.open()
    @$el.addClass('open')

  # passed through again to reach the Asset view.
  select: (model) =>
    @close()
    @trigger "select", model

  pickFile: (e) =>
    @ui.filefield.click()

  getPickedFile: (e) =>
    if files = @ui.filefield[0].files
      @readLocalFile files[0]

  readLocalFile: (file) =>
    if file?
      reader = new FileReader()
      reader.onloadend = =>
        @createModel reader.result, file
      reader.readAsDataURL(file)

  containEvent: (e) =>
    e?.stopPropagation()


class Cms.Views.AssetRemover extends Backbone.Marionette.View
  template: "assets/remover"
  className: "remover"

  ui:
    deleter: "a.delete"

  triggers:
    "click @ui.deleter": "remove"

  show: =>
    @$el.show()

  hide: =>
    @$el.hide()


class Cms.Views.ImagePicker extends Cms.Views.AssetPicker
  template: "assets/image_picker"

  initialize: (data, options={}) ->
    @collection ?= new Cms.Collections.Images
    super

  createModel: (data, file) =>
    @log "ImagePicker createModel", @collection
    model = @collection.add
      file_data: data
      file_name: file.name
      file_size: file.size
      file_type: file.type
    @select(model)
    model.save().done =>
      @trigger "create", model


class Cms.Views.ImageWeighter extends Cms.Views.MenuView
  tagName: "div"
  className: "weighter"
  template: "assets/weighter"

  ui:
    head: ".menu-head"
    body: ".menu-body"

  events:
    "click @ui.head": "toggleMenu"

  bindings: 
    "input.weight": "main_image_weighting"


class Cms.Views.VideoPicker extends Cms.Views.AssetPicker
  template: "assets/video_picker"

  initialize: ->
    @collection ?= new Cms.Collections.Videos
    super

  createModel: (data, file) =>
    model = @collection.unshift
      file_data: data
      file_name: file.name
      file_size: file.size
      file_type: file.type
    @select(model)
    model.save().done =>
      @trigger "create", model

