## Listed assets
#
# The submenu for each asset picker is a chooser-list derived AssetList.
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


class Cms.Views.AssetList extends Cms.CollectionView
  childView: Cms.Views.ListedAsset
  emptyView: Cms.Views.NoListedAsset

  childViewTriggers:
    'select': 'select'


class Cms.Views.ImageList extends Cms.Views.AssetList
  template: "assets/image_list"


class Cms.Views.VideoList extends Cms.Views.AssetList
  template: "assets/video_list"



## Individual Asset Managers
#
# The html we get and set can include a number of embedded assets...
#
class Cms.Views.Asset extends Cms.View
  defaultSize: "full"
  tagName: "figure"
  editorView: "AssetEditor"

  initialize: (opts={}) =>
    @wrap() or @render()

  # Previously embedded assets will come back in HTML form.
  # Each subclass will perform its own value extraction to decompose that into model + template.
  # NB wrap is only possible before render, since contents of el will be replaced.
  wrap: =>
    false

  onRender: =>
    @$el.attr "contenteditable", false
    @stickit() if @model
    @addEditor()

  onWrap: =>
    @addEditor()

  addEditor: =>
    if editor_view_class = Cms.Views[@getOption('editorView')]
      @_editor = new editor_view_class
        model: @model
      @_editor.$el.appendTo @$el
      @_editor.render()
      @_editor.on 'remove', @remove
      @_editor.on 'update', @update
      @_editor.on 'select', @setModel

  update: =>
    @log "update", @$el.parent()
    @$el.parent().trigger 'input'

  remove: () =>
    @$el.slideUp 'fast', =>
      @update()
      @$el.remove()

  setModel: (model) =>
    @model = model
    @stickit() if @model
    @update()


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
      @triggerMethod 'wrap'

  onRender: =>
    @model ?= new Cms.Models.Image
    super


class Cms.Views.BackgroundImage extends Cms.Views.Image
  template: false
  className: "bg"

  bindings:
    ":el":
      attributes: [
        name: "data-image",
        observe: "id"
      ,
        name: "style",
        observe: ["file_url", "file_data"]
        onGet: "styleBackgroundImage"
      ]


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
      updateMethod: "html"
    "video":
      observe: ["file_url", "embed_code"]
      visible: "thisButNotThat"
      attributes: [
        name: "id"
        observe: "id"
        onGet: "videoId"
      ,
        name: "poster"
        observe: "full_url"
      ]
    "img":
      attributes: [
        name: "src"
        observe: "full_url"
      ]
    "source":
      attributes: [
        name: "src"
        observe: "url"
      ]

  wrap: =>
    if video_id = @$el.data('video')
      @model = new Cms.Models.Video(id: video_id)
      @model.load()
      @triggerMethod 'wrap'

  onRender: =>
    @model ?= new Cms.Models.Video
    super

  unlessEmbedded: (embed_code) =>
    !embed_code

  hideVideo: (el, visible, model) =>
    el.hide() unless visible

  videoId: (id) =>
    "video_#{id}"


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




## Annotation pseudo-assets
#
# Just html, with no reference to an external asset, but editable and stylable like an embedded object.
#





