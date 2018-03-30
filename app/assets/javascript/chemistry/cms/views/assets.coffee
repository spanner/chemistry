## Individual Asset Managers
#
# The html we get and set can include a number of embedded assets...
#
class Cms.Views.Asset extends Cms.View
  defaultSize: "full"
  tagName: "figure"
  editorView: "AssetEditor"

  initialize: (opts={}) =>
    @wrap()
    @render()

  wrap: =>
    # Previously embedded assets will come back in HTML form.
    # Each subclass will perform its own value extraction to decompose that into model + template.
    # NB wrap is only possible before render, when contents of el will be replaced.

  onRender: =>
    @$el.attr "contenteditable", false
    @stickit() if @model
    @addEditor()
    @listenToEditor()

  addEditor: =>
    @log "🙈 addEditor", @getOption('editorView')
    if editor_view_class = Cms.Views[@getOption('editorView')]
      @_editor = new editor_view_class
        model: @model
      @_editor.$el.appendTo @$el
      @_editor.render()

  listenToEditor: =>
    @_editor.on 'remove', @remove
    @_editor.on 'update', @update
    @_editor.on 'select', @setModel

  update: =>
    @$el.parent().trigger 'input'

  remove: () =>
    @$el.slideUp 'fast', =>
      @$el.remove()
      @update()

  setModel: (model) =>
    @model = model
    @stickit() if @model
    @update()


class Cms.Views.AssetEditor extends Cms.View
  defaultSize: "full"
  stylerView: "AssetStyler"

  ui:
    buttons: ".cms-buttons"
    catcher: ".cms-dropmask"
    prompt: ".prompt"
    overlay: ".darken"
    deleter: "a.delete"

  triggers:
    "click @ui.deleter": "remove"

  events:
    "dragenter": "lookAvailable"
    "dragover @ui.catcher": "dragOver"
    "dragleave @ui.catcher": "lookNormal"
    "drop @ui.catcher": "catchFiles"
    "click @ui.catcher": "pickFile"

  initialize: (opts={}) =>
    @_size ?= _.result @, 'defaultSize'
    super

  onRender: =>
    @$el.attr('data-cms', true)
    @addHelpers()

  addHelpers: =>
    @addPicker()
    @listenToPicker()
    @addStyler()
    @listenToStyler()

  addPicker: =>
    if picker_view_class = Cms.Views[@getOption('pickerView')]
      @_picker = new picker_view_class
      @_picker.$el.appendTo @ui.buttons
      @_picker.render()

  listenToPicker: =>
    @_picker?.on "select", @setModel
    @_picker?.on "create", @savedModel

  addStyler: =>
    if _cms.getOption('asset_styles')
      if styler_view_class = Cms.Views[@getOption('stylerView')]
        @_styler = new styler_view_class
          model: @model
        @_styler.$el.appendTo @ui.buttons
        @_styler.render()

  listenToStyler: =>
    @_styler?.on "styled", @setStyle

  # picker selects a new model
  setModel: (model) =>
    @model = model
    @_styler?.setModel(model)
    @trigger "select", @model

  # picker populates our existing shared model
  savedModel: (model) =>
    @log "🙈 savedModel", model
    @stickit()

  setSize: (size) =>
    @_size = size
    @stickit() if @model

  setStyle: (style) =>
    @$el.removeClass('right left full').addClass(style)
    size = if style is "full" then "full" else "half"
    @setSize size
    @update()

  lookAvailable: (e) =>
    @log "lookAvailable"
    e?.stopPropagation()
    @$el.addClass('droppable')

  lookNormal: (e) =>
    e?.stopPropagation()
    @$el.removeClass('droppable')

  dragOver: (e) =>
    @log "dragOver"
    e?.preventDefault()
    if e.originalEvent.dataTransfer
      e.originalEvent.dataTransfer.dropEffect = 'copy'

  catchFiles: (e) =>
    @lookNormal()
    if e?.originalEvent.dataTransfer?.files.length
      @containEvent(e)
      @readFile e.originalEvent.dataTransfer.files
    else
      console.log "unreadable drop", e

  readFile: (files) =>
    @_picker?.readLocalFile(files[0]) if files.length

  pickFile: (e) =>
    @containEvent(e)
    @_picker?.pickFile(e)


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
      @_menu_view.on "select", @setModel
    @collection.reload()
    @_menu_view.open()
    @$el.addClass('open')

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

  createModel: (data, file) =>
    #noop here: subclass must define

  # passed through again to reach the Asset view.
  setModel: (model) =>
    @close()
    @trigger "select", model


## Image assets
#
class Cms.Views.Image extends Cms.Views.Asset
  editorView: "ImageEditor"
  template: "assets/image"
  className: "image full"
  defaultSize: "full"

  bindings:
    ":el":
      attributes: [
        name: "data-image",
        observe: "id"
      ]
    "img":
      attributes: [
        name: "src"
        observe: ["file_url", "file_data"]
        onGet: "thisOrThat"
      ]

  wrap: =>
    if image_id = @$el.data('image')
      @model = new Cms.Models.Image(id: image_id)
      @model.load()
    @model ?= new Cms.Models.Image


class Cms.Views.ImageEditor extends Cms.Views.AssetEditor
  template: "assets/image_editor"
  className: "cms-editor"
  pickerView: "ImagePicker"
  stylerView: "AssetStyler"


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
    @setModel(model)
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



## Video assets
#
class Cms.Views.Video extends Cms.Views.Asset
  editorView: "VideoEditor"
  template: "assets/video"
  className: "video full"
  defaultSize: "full"

  events:
    "click a.save": "saveVideo"

  bindings:
    ":el":
      attributes: [
        name: "data-video",
        observe: "id"
      ]
    ".embed":
      observe: "embed_code"
      visible: true
      updateView: true
      updateMethod: "html"
    "video":
      observe: "embed_code"
      visible: "unlessEmbedded"
      visibleFn: "hideVideo"

  wrap: =>
    @$el.addClass 'editing'
    if video_id = @$el.data('video')
      _cms.withAssets =>
        @setModel _cms.videos.get(video_id ) ? new Cms.Models.Video

  unlessEmbedded: (embed_code) =>
    !embed_code

  hideVideo: (el, visible, model) =>
    el.hide() unless visible


class Cms.Views.VideoEditor extends Cms.Views.AssetEditor
  template: "assets/video_editor"
  pickerView: "VideoPicker"


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


## Quote pseudo-assets
#
# Just html, with no reference to an external asset, but editable and stylable like an embedded object.
#
class Cms.Views.Quote extends Cms.Views.Asset
  editorView: "QuoteEditor"
  template: "assets/quote"
  className: "quote full"
  defaultSize: "full"

  ui:
    quote: "blockquote"
    caption: "figcaption"

  bindings:
    ":el":
      attributes: [
        name: "class"
        observe: "utterance"
        onGet: "classFromLength"
      ]
    "blockquote":
      observe: "utterance"
    "figcaption":
      observe: "caption"

  wrap: =>
    @model = new Cms.Models.Quote
      utterance: @$el.find('blockquote').text()
      caption: @$el.find('figcaption').text()

  focus: =>
    @ui.quote.focus()

  classFromLength: (text="") =>
    l = text.replace(/&nbsp;/g, ' ').trim().length
    if l < 24
      "veryshort"
    else if l < 48
      "short"
    else if l < 96
      "shortish"
    else
      ""


class Cms.Views.QuoteEditor extends Cms.Views.AssetEditor
  template: "assets/quote_editor"


## Annotation pseudo-assets
#
# Just html, with no reference to an external asset, but editable and stylable like an embedded object.
#
