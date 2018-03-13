## Asset-choosers
#
# The submenu for each asset picker is a chooser-list.
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
        observe: 'icon_url'
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

  onRender: =>
    @stickit()
    @_progress = new Cms.Views.ProgressBar
      model: @model
      size: 40
      thickness: 10
    @_progress.$el.appendTo @$el
    @_progress.render()

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


class Cms.Views.NoAsset extends Cms.View
  template: "assets/no_asset"
  tagName: "li"
  className: "empty"


class Cms.Views.AssetsList extends Cms.CompositeView
  template: "assets/list"
  childViewContainer: "ul.cms-assets"
  childView: Cms.Views.ListedAsset
  emptyView: Cms.Views.NoAsset

  events:
    "click a.import": "importAsset"
    "click a.next": "nextPage"
    "click a.prev": "prevPage"

  childViewEvents:
    'select': 'select'

  ui:
    'heading': 'span.heading'
    'search_field': 'input.q'
    'prev_button': 'a.prev'
    'next_button': 'a.next'
    'import_field': 'input.remote_url'
    'import_button': 'a.import'

  initialize: (opts={}) =>
    @_q = ""
    @_p = 1
    @_title = opts.title ? "Assets"
    @_master_collection = @collection.clone()
    @_master_collection.on "reset", @selectAssets
    @_filterSoon = _.debounce @selectAssets, 250
    $.al = @

  onRender: =>
    @ui.heading.text @_title
    @ui.search_field.on 'input', @_filterSoon
    @selectAssets()

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

  selectAssets: (e, q) =>
    first = (@_p - 1) * 20
    last = first + 20
    if q = @ui.search_field.val()
      re = new RegExp(q, 'i')
      matches = @_master_collection.select (image) ->
        re.test(image.get('title')) or re.test(image.get('caption'))
    else
      matches = @_master_collection.toArray()

    @collection.reset matches.slice(first,last)

    total = matches.length
    if total > last
      @ui.next_button.removeClass('inactive')
    else
      @ui.next_button.addClass('inactive')
    if first == 0
      @ui.prev_button.addClass('inactive')
    else
      @ui.prev_button.removeClass('inactive')

  nextPage: =>
    @_p = @_p + 1
    @selectAssets()

  prevPage: =>
    @_p = @_p - 1
    @_p = 1 if @_p < 1
    @selectAssets()


## Asset-pickers
#
# These menus are embedded in the asset view. They select from an asset collection to
# set the model in the asset view, with the option to upload or import new items.
#
class Cms.Views.AssetPicker extends Cms.Views.MenuView
  tagName: "div"
  className: "picker"
  menuView: Cms.Views.AssetsList

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
      @_menu_view = new Cms.Views.AssetsList
        collection: @collection
      @ui.body.append @_menu_view.el
      @_menu_view.render()
      @_menu_view.on "select", @select
    @_menu_view.open()
    @$el.addClass('open')

  # passed through again to reach the Asset view.
  select: (model) =>
    @close()
    @trigger "select", model

  pickFile: (e) =>
    console.log "pickFile", e.target or e.originalEvent.target
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
  template: "remover"
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
  template: "image_picker"

  initialize: (data, options={}) ->
    @collection ?= _cms.images
    super

  createModel: (data, file) =>
    model = @collection.add
      file: data
      file_name: file.name
      file_size: file.size
      file_type: file.type
    @select(model)
    model.save().done =>
      @trigger "create", model


class Cms.Views.VideoPicker extends Cms.Views.AssetPicker
  template: "video_picker"

  initialize: ->
    @collection ?= _cms.videos
    super

  createModel: (data, file) =>
    model = @collection.unshift
      file: data
      file_name: file.name
      file_size: file.size
      file_type: file.type
    @select(model)
    model.save().done =>
      @trigger "create", model


class Cms.Views.QuotePicker extends Cms.Views.AssetPicker
  template: "quote_picker"
  title: "Quotes"
