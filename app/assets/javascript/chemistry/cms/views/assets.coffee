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


class Cms.Views.ListedDocument extends Cms.Views.ListedAsset
  template: "assets/listed_document"
  tagName: "li"
  className: "document"

  events:
    "click a.delete": "deleteModel"
    "click a.document": "selectMe"

  bindings:
    ":el":
      attributes: [
        name: "data-document",
        observe: "id"
      ]
    "a.preview":
      attributes: [
        name: "href"
        observe: "file_url"
      ]
    "img.icon":
      attributes: [
        name: "src"
        observe: "icon_url"
        onGet: "iconOrDefault"
      ]
    "span.label":
      observe: ["title", "file_name"]
      onGet: "thisOrThat"

  iconOrDefault: (icon_url) =>
    icon_url or "/images/file_types/pdf.png"



class Cms.Views.AssetList extends Cms.CollectionView
  childView: Cms.Views.ListedAsset
  emptyView: Cms.Views.NoListedAsset
  tagName: "ul"
  className: "cms-assets"

  childViewTriggers:
    'select': 'select'


class Cms.Views.ImageList extends Cms.Views.AssetList


class Cms.Views.VideoList extends Cms.Views.AssetList


class Cms.Views.DocumentList extends Cms.Views.AssetList
  childView: Cms.Views.ListedDocument


## Individual Asset Managers
#
# The html we get and set can include a number of embedded assets...
#
class Cms.Views.Asset extends Cms.View
  defaultSize: "full"
  tagName: "figure"
  editorView: "AssetEditor"

  ui:
    catcher: "erm"

  # events:
  #   "dragenter": "lookAvailable"
  #   "dragover": "dragOver"
  #   "dragleave": "lookNormal"
  #   "drop": "catchFiles"

  initialize: (opts={}) =>
    @bindUIElements();

  render: =>
    @wrap() or super

  # Previously embedded assets come back to us in HTML form.
  # Each subclass performs its own value extraction to decompose that into model + template.
  # NB wrap is only possible before render, since contents of el will then be replaced.
  wrap: =>
    false

  onRender: =>
    @$el.attr "contenteditable", false
    @stickit() if @model
    @addEditor()

  onWrap: =>
    @addEditor()
    @setPlaceholders()

  addEditor: =>
    if editor_view_class = Cms.Views[@getOption('editorView')]
      @_editor = new editor_view_class
        model: @model
      @_editor.$el.appendTo @$el
      @_editor.render()
      @_editor.on 'remove', @remove
      @_editor.on 'update', @onUpdate
      @_editor.on 'place', @onPlace
      @_editor.on 'select', @setModel

  setPlaceholders: =>
    #

  remove: () =>
    @$el.slideUp 'fast', =>
      p = $("<p />").insertBefore @$el
      @$el.remove()
      p.focus()
      @onUpdate()

  setModel: (model) =>
    @model = model
    @stickit() if @model
    @onUpdate()

  # relay update event from helpers up to containing editable
  onUpdate: =>
    @log "🚜 asset onUpdate"
    @trigger 'update'

  onPlace: (placement) =>
    @log "🚜 onPlace", placement
    @$el.removeClass('thumb full right').addClass(placement)
    @trigger 'update'

  ## Dropped-file handlers
  # Live here so as to be applied to the whole asset element.
  # Dropped file is passed to our uploader for processing.
  #
  # dragOver: (e) =>
  #   e?.preventDefault()
  #   if e.originalEvent.dataTransfer
  #     e.originalEvent.dataTransfer.dropEffect = 'copy'
  #
  # catchFiles: (e) =>
  #   @lookNormal()
  #   if e?.originalEvent.dataTransfer?.files.length
  #     @containEvent(e)
  #     @readFile e.originalEvent.dataTransfer.files
  #   else
  #     console.log "unreadable drop", e
  #
  # readFile: (files) =>
  #   @_uploader.readLocalFile(files[0]) if @_uploader and files.length
  #
  # lookAvailable: (e) =>
  #   e?.stopPropagation()
  #   @$el.addClass('droppable')
  #
  # lookNormal: (e) =>
  #   e?.stopPropagation()
  #   @$el.removeClass('droppable')



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
    @log "🎁 Wrapping", @$el.html()
    if image_id = @$el.data('image')
      @model = new Cms.Models.Image(id: image_id)
      @model.load()
      @triggerMethod 'wrap'
      true

  onRender: =>
    @log "🎁 Rendering", @$el.html()
    @model ?= new Cms.Models.Image
    super

  setPlaceholders: =>
    @$el.find('figcaption')
      .attr('contenteditable', 'true')
      .attr('data-placeholder', t("placeholders.caption"))


## Video assets
#
class Cms.Views.Video extends Cms.Views.Asset
  editorView: "VideoEditor"
  template: "assets/video"
  className: "video full"
  defaultSize: "full"

  bindings:
    ":el":
      attributes: [
        name: "data-video",
        observe: "id"
      ]
    ".embed":
      observe: "embed_code"
      updateMethod: "html"
      classes:
        unnecessary: "mp4_url"
    "video":
      observe: ["file_url", "embed_code"]
      visible: "thisButNotThat"
      attributes: [
        name: "id"
        observe: "id"
        onGet: "videoId"
      ,
        name: "poster"
        observe: "hero_url"
      ]
    "img":
      attributes: [
        name: "src"
        observe: "hero_url"
      ]
    "source":
      attributes: [
        name: "src"
        observe: "mp4_url"
      ]

  wrap: =>
    if video_id = @$el.data('video')
      @model = new Cms.Models.Video(id: video_id)
      @model.load()
      @triggerMethod 'wrap'

  onRender: =>
    @model ?= new Cms.Models.Video
    super

  setPlaceholders: =>
    @$el.find('figcaption')
      .attr('contenteditable', 'true')
      .attr('data-placeholder', t("placeholders.caption"))

  unlessEmbedded: (embed_code) =>
    !embed_code

  hideVideo: (el, visible, model) =>
    el.hide() unless visible

  videoId: (id) =>
    "video_#{id}"


## Background asset
#  Could be image or video, has pickers and choosers for both.
#  The variable model class creates some clumsy bindings to properties that might not exist
#  and relies on a clunky 'asset_type' pseudo-attribute, but it gives the user a simple and consistent UI.
#
class Cms.Views.Background extends Cms.Views.Asset
  editorView: "ImageOrVideoEditor"
  template: "assets/background"
  className: "bg"

  bindings:
    ":el":
      classes:
        img:
          observe: "asset_type"
          onGet: "ifImage"
        vid:
          observe: "asset_type"
          onGet: "ifVideo"
      attributes: [
        name: "data-asset-id",
        observe: "id"
      ,
        name: "data-asset-type",
        observe: "asset_type"
      ]
    ".embed":
      observe: ["asset_type", "embed_code"]
      visible: "ifEmbeddedVideo"
      updateView: true
      updateMethod: "html"
    "video":
      observe: ["asset_type", "original_url", "embed_code"]
      visible: "ifUnembeddedVideo"
      attributes: [
        name: "poster"
        observe: "file_url"
      ,
        name: "src"
        observe: "original_url"
      ]
    "img":
      observe: "asset_type"
      visible: "ifImage"
      attributes: [
        name: "src"
        observe: "file_url"
      ]

  wrap: =>
    if asset_id = @$el.data('asset-id')
      if @$el.data('asset-type') is 'video'
        @model = new Cms.Models.Video(id: asset_id)
      else
        @model = new Cms.Models.Image(id: asset_id)
      @model.load()
      @triggerMethod 'wrap'

  ifImage: (asset_type) =>
    asset_type is "image"

  ifVideo: (asset_type) =>
    asset_type is "video"

  ifEmbeddedVideo: ([asset_type, embed_code]=[]) =>
    asset_type is "video" and embed_code

  ifUnembeddedVideo: ([asset_type, original_url, embed_code]=[]) =>
    asset_type is "video" and original_url and not embed_code

  styleBackgroundIfImage: ([asset_type, file_url, file_data]=[]) =>
    if asset_type is "image"
      @styleBackgroundImage([file_url, file_data])
    else
      ""


## Document assets
#
class Cms.Views.Document extends Cms.Views.Asset
  editorView: "DocumentEditor"
  template: "assets/document"
  className: "document"

  bindings:
    ":el":
      attributes: [
        name: "data-document",
        observe: "id"
      ]
    "a.document":
      attributes: [
        name: "href"
        observe: "file_url"
      ]
      classes:
        missing:
          observe: "file_url"
          onGet: "untrue"
    "img.icon":
      attributes: [
        name: "src"
        observe: "icon_url"
        onGet: "iconOrDefault"
      ]
    "span.filename":
      observe: ["title", "file_name"]
      onGet: "titleOrPrompt"

  wrap: =>
    if document_id = @$el.data('document')
      @model = new Cms.Models.Document(id: document_id)
      @model.load()
      @triggerMethod 'wrap'

  onRender: =>
    @model ?= new Cms.Models.Document
    super

  documentId: (id) =>
    "document_#{id}"

  titleOrPrompt: ([title, file_name]=[]) =>
    title or file_name or t("placeholders.document.file")

  iconOrDefault: (icon_url) =>
    icon_url or "/images/file_types/pdf.png"



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
    @log "→ wrapped quote", @el, _.clone(@model.attributes)

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


## Annotation (Note) pseudo-assets
#
# Just html, with no reference to an external asset, but editable and stylable like an embedded object.
#
class Cms.Views.Note extends Cms.Views.Asset
  editorView: "NoteEditor"
  template: "assets/note"
  tagName: "div"
  className: "aside"

  ui:
    text: "p"

  bindings:
    "p": "text"

  wrap: =>
    @model = new Cms.Models.Note
      text: @ui.text.text()
    @triggerMethod 'wrap'

  onRender: =>
    @model ?= new Cms.Models.Note
    super

  focus: =>
    @ui.text.focus()
