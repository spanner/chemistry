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
    "click a.document": "addDocument"
    "click a.quote": "addQuote"
    "click a.note": "addNote"

  initialize: (@options={}) ->
    @log "👉 init", @options
    @_target_el = @options.target
    @_p = null

  onRender: () =>
    @log "👉 render"
    @$el.appendTo _cms.el
    @_target_el.on "click keyup focus", @followCaret

  followCaret: (e)=>
    @log "👉 followCaret"
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

  addDocument: (e) =>
    e?.preventDefault()
    @insert new Cms.Views.Document

  addQuote: (e) =>
    e?.preventDefault()
    @insert new Cms.Views.Quote

  addNote: (e) =>
    e?.preventDefault()
    @insert new Cms.Views.Note

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
    @log "👉 inserted", view.el
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


## Asset editors
#
# Wrap around an embedded asset to present controls for editing or replacing it.
# The editor is responsible for adding pickers, stylers, importers and so on.
# We also catch some events here and pass them on, so as to present a broad target,
# including click to select and drop to upload. 
#
class Cms.Views.AssetEditor extends Cms.View
  defaultSize: "full"
  stylerView: "AssetStyler"
  importerView: "AssetImporter"
  uploaderView: "AssetUploader"

  ui:
    catcher: ".cms-dropmask"
    buttons: ".cms-buttons"
    deleter: "a.delete"

  triggers:
    "click @ui.deleter": "remove"

  events:
    "click @ui.catcher": "closeHelpers"
    "dragenter @ui.catcher": "lookAvailable"
    "dragover @ui.catcher": "dragOver"
    "dragleave @ui.catcher": "lookNormal"
    "drop @ui.catcher": "catchFiles"

  initialize: (opts={}) =>
    @_size ?= _.result @, 'defaultSize'
    super

  onRender: =>
    @$el.attr('data-cms', true)
    @addHelpers()

  addHelpers: =>
    if uploader_view_class = Cms.Views[@getOption('uploaderView')]
      @_uploader = new uploader_view_class
        collection: @collection
      @_uploader.$el.appendTo @ui.buttons
      @_uploader.render()
      @_uploader.on "select", @setModel
      @_uploader.on "create", @update
      @_uploader.on "pick", => @closeHelpers()

    if importer_view_class = Cms.Views[@getOption('importerView')]
      @_importer = new importer_view_class
        collection: @collection
      @_importer.$el.appendTo @ui.buttons
      @_importer.render()
      @_importer.on "select", @setModel
      @_uploader.on "create", @update
      @_importer.on "open", => @closeOtherHelpers(@_importer)

    if picker_view_class = Cms.Views[@getOption('pickerView')]
      @_picker = new picker_view_class
        collection: @collection
      @_picker.$el.appendTo @ui.buttons
      @_picker.render()
      @_picker.on "select", @setModel
      @_picker.on "open", => @closeOtherHelpers(@_picker)

    if _cms.getOption('asset_styles')
      if styler_view_class = Cms.Views[@getOption('stylerView')]
        @_styler = new styler_view_class
          model: @model
        @_styler.$el.appendTo @ui.buttons
        @_styler.render()
        @_styler.on "styled", @setStyle
        @_styler.on "open", => @closeOtherHelpers(@_styler)


  ## Selection controls
  #
  setModel: (model) =>
    @log "🤡 setModel", model
    @model = model
    @_styler?.setModel(model)
    if @model
      @trigger "select", @model
      @stickit()

  update: =>
    @trigger 'update'

  ## Styling controls
  #
  setSize: (size) =>
    @_size = size
    @stickit() if @model

  setStyle: (style) =>
    @$el.removeClass('right left full').addClass(style)
    size = if style is "full" then "full" else "half"
    @setSize size
    @update()


  ## Dropped-file handlers
  # Live here so as to be applied to the whole asset element.
  # Dropped file is passed to our uploader for processing.
  #
  dragOver: (e) =>
    @log "🤡 dragOver"
    e?.preventDefault()
    if e.originalEvent.dataTransfer
      e.originalEvent.dataTransfer.dropEffect = 'copy'

  catchFiles: (e) =>
    @lookNormal()
    @log "🤡 catchFiles", e?.originalEvent.dataTransfer?.files
    if e?.originalEvent.dataTransfer?.files.length
      @containEvent(e)
      @readFile e.originalEvent.dataTransfer.files
    else
      console.log "unreadable drop", e

  readFile: (files) =>
    @_uploader.readLocalFile(files[0]) if @_uploader and files.length

  lookAvailable: (e) =>
    @log "🤡 lookAvailable"
    e?.stopPropagation()
    @$el.addClass('droppable')

  lookNormal: (e) =>
    @log "🤡 lookNormal"
    e?.stopPropagation()
    @$el.removeClass('droppable')

  ## Click handler
  # allows click anywhere to upload. Event is relayed to uploader.
  #
  pickFile: (e) =>
    e?.preventDefault()
    @_uploader?.pickFile(e)

  ## Menu display

  closeHelpers: =>
    # event allowed through
    _.each [@_picker, @_importer, @_styler], (h) ->
      h?.close()

  closeOtherHelpers: (helper) =>
    _.each [@_picker, @_importer, @_styler], (h) ->
      h?.close() unless h is helper


class Cms.Views.ImageEditor extends Cms.Views.AssetEditor
  template: "assets/image_editor"
  pickerView: "ImagePicker"
  importerView: "ImageImporter"
  uploaderView: "ImageUploader"

  initialize: (data, options={}) ->
    @collection ?= new Cms.Collections.Images
    super


class Cms.Views.VideoEditor extends Cms.Views.AssetEditor
  template: "assets/video_editor"
  pickerView: "VideoPicker"
  importerView: "VideoImporter"
  uploaderView: "VideoUploader"

  initialize: ->
    @collection ?= new Cms.Collections.Videos
    super


class Cms.Views.DocumentEditor extends Cms.Views.AssetEditor
  template: "assets/document_editor"
  pickerView: "DocumentPicker"
  uploaderView: "DocumentUploader"

  initialize: (data, options={}) ->
    @collection ?= new Cms.Collections.Documents
    super


class Cms.Views.QuoteEditor extends Cms.Views.AssetEditor
  template: "assets/quote_editor"


class Cms.Views.NoteEditor extends Cms.Views.AssetEditor
  template: "assets/note_editor"


## Asset pickers
#
# Display a list of assets, receive a selection click and call setModel on the Asset container.
#
class Cms.Views.AssetPicker extends Cms.Views.MenuView
  tagName: "div"
  className: "picker"
  listView: "AssetsList"

  ui:
    head: ".menu-head"
    body: ".menu-body"
    list: "ul.cms-assets"
    closer: "a.close"

  onOpen: =>
    unless @_list_view
      list_view_class = @getOption('listView')
      @_list_view = new Cms.Views[list_view_class]
        collection: @collection
      @ui.list.append @_list_view.el
      @_list_view.on "select", @setModel
    @collection.reload()
    @_list_view.render()

  # passed back to the Asset view.
  setModel: (model) =>
    @close()
    @trigger "select", model


class Cms.Views.ImagePicker extends Cms.Views.AssetPicker
  template: "assets/image_picker"
  listView: "ImageList"


class Cms.Views.VideoPicker extends Cms.Views.AssetPicker
  template: "assets/video_picker"
  listView: "VideoList"


class Cms.Views.DocumentPicker extends Cms.Views.AssetPicker
  template: "assets/document_picker"
  listView: "DocumentList"


## Asset importers
#
# Take a URL, turn it into an Asset and call setModel on the Asset container.
#
class Cms.Views.AssetImporter extends Cms.Views.MenuView
  tagName: "div"
  className: "importer"

  ui:
    head: ".menu-head"
    body: ".menu-body"
    url: "input.remote_url"
    button: "a.submit"
    closer: "a.close"
    waiter: "p.waiter"

  events:
    "click @ui.head": "toggleMenu"
    "click @ui.closer": "close"
    "click @ui.button": "createModel"

  createModel: =>
    if remote_url = @ui.url.val()
      model = @collection.add
        remote_url: remote_url
      @trigger 'select', model
      @disableForm()
      model.save().done =>
        @trigger 'create', model
        @resetForm()
        @close()

  disableForm: =>
    @ui.url.attr('disabled', true)
    @ui.button.addClass('waiting')
    @ui.waiter.show()

  resetForm: =>
    @ui.button.removeClass('waiting')
    @ui.url.removeAttr('disabled')
    @ui.waiter.hide()
    @ui.url.val("")


class Cms.Views.ImageImporter extends Cms.Views.AssetImporter
  template: "assets/image_importer"


class Cms.Views.VideoImporter extends Cms.Views.AssetImporter
  template: "assets/video_importer"


class Cms.Views.DocumentImporter extends Cms.Views.AssetImporter
  template: "assets/document_importer"


## Asset uploaders
#
# Take a file, turn it into an Asset and call setModel on the Asset container.
#
class Cms.Views.AssetUploader extends Cms.View
  tagName: "div"
  className: "uploader"

  ui:
    label: "label"
    filefield: 'input[type="file"]'
    prompt: ".prompt"

  events:
    "click @ui.filefield": "containEvent"
    "change @ui.filefield": "getPickedFile"
    "click @ui.label": "triggerPick"

  ## Picked-file handlers
  #
  # `pickFile` can be called from outside the uploader.
  pickFile: (e) =>
    e?.preventDefault()
    e?.stopPropagation()
    @trigger 'pick'
    @ui.filefield.click()

  triggerPick: =>
    # event is allowed to continue.
    @trigger 'pick'

  # then `getPickedFile` is called on filefield change.
  getPickedFile: (e) =>
    if files = @ui.filefield[0].files
      @readLocalFile files[0]

  # `readLocalFile` is called either from here or from the outer Editor on file drop.
  readLocalFile: (file) =>
    if file?
      reader = new FileReader()
      reader.onloadend = =>
        @createModel reader.result, file
      reader.readAsDataURL(file)

  createModel: (data, file) =>
    model = @collection.add
      file_data: data
      file_name: file.name
      file_size: file.size
      file_type: file.type
    @trigger "select", model
    model.save().done =>
      @trigger "create", model

  containEvent: (e) =>
    e?.stopPropagation()


class Cms.Views.ImageUploader extends Cms.Views.AssetUploader
  template: "assets/image_uploader"
  

class Cms.Views.VideoUploader extends Cms.Views.AssetUploader
  template: "assets/video_uploader"


class Cms.Views.DocumentUploader extends Cms.Views.AssetUploader
  template: "assets/document_uploader"


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

