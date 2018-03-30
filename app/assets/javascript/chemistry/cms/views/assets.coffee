## Individual Asset Managers
#
# The html we get and set can include a number of embedded assets...
#
class Cms.Views.Asset extends Cms.View
  defaultSize: "full"
  tagName: "figure"

  ui:
    buttons: ".cms-buttons"
    catcher: ".cms-dropmask"
    prompt: ".prompt"
    overlay: ".darken"

  events:
    "dragenter": "lookAvailable"
    "dragover @ui.catcher": "dragOver"
    "dragleave @ui.catcher": "lookNormal"
    "drop @ui.catcher": "catchFiles"
    "click @ui.catcher": "pickFile"

  initialize: =>
    @_size ?= _.result @, 'defaultSize'
    super

  wrap: =>
    #required in subclass to extract model properties from html.

  onRender: =>
    @$el.attr "contenteditable", false
    @stickit() if @model
    @addHelpers()

  addHelpers: =>
    @addPicker()
    @listenToPicker()
    @addRemover()
    @listenToRemover()
    @addStyler()
    @listenToStyler()
    @addConfig()

  addPicker: =>
    @log "addPicker", @getOption('pickerView')
    if picker_view_class = Cms.Views[@getOption('pickerView')]
      @_picker = new picker_view_class
      @_picker.$el.appendTo @ui.buttons
      @_picker.render()

  listenToPicker: =>
    @_picker?.on "select", @setModel
    @_picker?.on "create", @savedModel

  addRemover: =>
    @_remover = new Cms.Views.AssetRemover
      model: @model
    @_remover.$el.appendTo @ui.buttons
    @_remover.render()
  
  listenToRemover: =>
    @_remover.on "remove", @remove

  withinBlock: =>
    console.log "withinBlock?", !!@$el.parents('.block').length
    !!@$el.parents('.block').length

  addStyler: =>
    if _cms.getOption('asset_styles') and not @withinBlock()
      if styler_view_class = Cms.Views[@getOption('stylerView')]
        @_styler = new styler_view_class
          model: @model
        @_styler.$el.appendTo @ui.buttons
        @_styler.render()

  listenToStyler: =>
    @_styler?.on "styled", @setStyle

  addConfig: =>
    if config_view_class = @getOption('configView')
      @_config = new config_view_class
        model: @model
      @_config.$el.appendTo @ui.buttons
      @_config.render()

  setModel: (model) =>
    @model = model
    @stickit() if @model
    @_styler?.setModel(model)
    @_progress?.setModel(model)
    @trigger "select"
    @ui.prompt.hide()
    @update()

  savedModel: =>
    @stickit()

  update: =>
    @$el.parent().trigger 'input'

  setSize: (size) =>
    @_size = size
    @stickit() if @model

  setStyle: (style) =>
    @$el.removeClass('right left full').addClass(style)
    size = if style is "full" then "full" else "half"
    @setSize size
    @update()

  remove: () =>
    @$el.slideUp 'fast', =>
      @$el.remove()
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


  # bindings for use within an asset model.
  #
  urlAtSize: (url) =>
    @model.get("#{@_size}_url") ? url

  backgroundAtSize: (url) =>
    if url
      "background-image: url('#{@urlAtSize(url)}')"

  weightedBackground: ([url, weighting]=[]) =>
    style = ""
    if url
      style += "background-image: url('#{@urlAtSize(url)}')"
      if weighting
        style += "; background-position: #{weighting}"
    style


class Cms.Views.Image extends Cms.Views.Asset
  pickerView: "ImagePicker"
  stylerView: "AssetStyler"
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
    "figcaption":
      observe: "caption"
    "a.save":
      observe: "changed"
      visible: true

  wrap: =>
    if image_id = @$el.data('image')
      _cms.withAssets =>
        @setModel _cms.images.get(image_id) ? new Cms.Models.Image
    else
      @model = new Cms.Models.Image

  saveImage: (e) =>
    e?.preventDefault()
    @model.save()


class Cms.Views.Video extends Cms.Views.Asset
  pickerView: "VideoPicker"
  stylerView: "AssetStyler"
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
    "figcaption":
      observe: "caption"

  wrap: =>
    @$el.addClass 'editing'
    if video_id = @$el.data('video')
      _cms.withAssets =>
        @setModel _cms.videos.get(video_id ) ? new Cms.Models.Video

  unlessEmbedded: (embed_code) =>
    !embed_code

  hideVideo: (el, visible, model) =>
    el.hide() unless visible


class Cms.Views.Quote extends Cms.Views.Asset
  stylerView: "AssetStyler"
  template: "assets/quote"
  className: "quote full"
  defaultSize: "full"

  ui:
    buttons: ".cms-buttons"
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

