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
    "click a.linkbutton": "addButton"
    "click a.quote": "addQuote"
    "click a.note": "addNote"

  initialize: (@options={}) ->
    @_target_view = @options.target
    @_target_el = @_target_view.$el
    @_p = null

  onRender: () =>
    @$el.appendTo _cms.el
    @_target_el.on "click keyup focus", @followCaret

  followCaret: (e)=>
    selection = @el.ownerDocument.getSelection()
    if !selection or selection.rangeCount is 0
      current = $(e.target)
    else
      range = selection.getRangeAt(0)
      current = $(range.commonAncestorContainer)
    @_p = current.closest('p')
    text = @_p.text()
    if @_p.length and _.isBlank(text) or text is "​" # zwsp!
      @show(@_p)
    else
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

  addButton: (e) =>
    e?.preventDefault()
    @insert new Cms.Views.LinkButton

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
    @_target_view.addView(view)
    @_target_el.trigger 'input'
    @log "🚜 inserted", view.el
    @hide()
    view.focus?()

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
  helpers: []

  ui:
    buttons: ".cms-buttons"
    deleter: "a.delete"

  triggers:
    "click @ui.deleter": "remove"

  initialize: (opts={}) =>
    @_size ?= _.result @, 'defaultSize'
    @_asset_helpers = []
    super

  onRender: =>
    @$el.attr('data-cms', true)
    @addHelpers()
    @setModel(@model) if @model
    @log "rendered", @model, @ui.buttons

  addHelpers: =>
    if helpers = @getOption('helpers')
      for helper_class_name in @getOption('helpers')
        if helper_class = Cms.Views[helper_class_name]
          helper = new helper_class
            collection: @collectionForHelper(helper_class_name)
          do (helper) =>
            helper.$el.appendTo @ui.buttons
            helper.render()
            @_asset_helpers.push helper
            helper.on "select", @setModel
            helper.on "create", @updateParent
            helper.on "place", @setPlacement
            helper.on "pick", => @closeHelpers()
            helper.on "open", => 
              @log "🚜 opened", helper
              @closeOtherHelpers(helper)

  collectionForHelper: (helper) =>
    @collection

  ## Selection actions
  #
  setModel: (model) =>
    @model = model
    for helper in @_asset_helpers
      helper.setModel?(helper)
    if @model
      @trigger "select", @model
      @stickit()
      @

  updateParent: =>
    @trigger 'update'


  ## Styling actions
  #
  setSize: (size) =>
    @_size = size
    @stickit() if @model

  setPlacement: (placement) =>
    size = if placement is "full" then "full" else "half"
    @setSize size
    @trigger "place", placement


  ## Menu management

  closeHelpers: =>
    # event allowed through
    for h in @_asset_helpers
      h?.close?()

  closeOtherHelpers: (helper) =>
    for h in _.without(@_asset_helpers, helper)
      h?.close?()


class Cms.Views.ImageEditor extends Cms.Views.AssetEditor
  template: "assets/image_editor"
  helpers: ["ImagePicker", "ImageImporter", "ImageUploader", "AssetPlacement"]

  initialize: (data, options={}) ->
    @collection ?= new Cms.Collections.Images
    super


class Cms.Views.VideoEditor extends Cms.Views.AssetEditor
  template: "assets/video_editor"
  helpers: ["VideoPicker", "VideoImporter", "VideoUploader", "AssetPlacement"]

  initialize: ->
    @collection ?= new Cms.Collections.Videos
    super


class Cms.Views.ImageOrVideoEditor extends Cms.Views.AssetEditor
  template: "assets/image_or_video_editor"
  helpers: ["ImagePicker", "ImageImporter", "ImageUploader", "VideoPicker", "VideoImporter", "VideoUploader"]

  initialize: ->
    @log "ImageOrVideoEditor init"
    @image_collection ?= new Cms.Collections.Images
    @video_collection ?= new Cms.Collections.Videos
    super

  collectionForHelper: (helper) =>
    if helper in ["VideoPicker", "VideoImporter", "VideoUploader"]
      @video_collection
    else
      @image_collection


class Cms.Views.DocumentEditor extends Cms.Views.AssetEditor
  template: "assets/document_editor"
  helpers: ["DocumentPicker", "DocumentUploader"]

  initialize: (data, options={}) ->
    @collection ?= new Cms.Collections.Documents
    super


class Cms.Views.QuoteEditor extends Cms.Views.AssetEditor
  template: "assets/quote_editor"

class Cms.Views.LinkButtonEditor extends Cms.Views.AssetEditor
  template: "assets/linkbutton_editor"

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
    list: ".pick"
    closer: "a.close"

  onOpen: =>
    unless @_list_view
      list_view_class = @getOption('listView')
      @_list_view = new Cms.Views[list_view_class]
        collection: @collection
      @ui.list.append @_list_view.el
      @_list_view.on "select", @selectModel
    @collection.reload()
    @_list_view.render()

  # passed back to the Asset view.
  selectModel: (model) =>
    @close()
    @trigger "select", model


class Cms.Views.ImagePicker extends Cms.Views.AssetPicker
  template: "assets/image_picker"
  listView: "ImageList"


class Cms.Views.VideoPicker extends Cms.Views.AssetPicker
  template: "assets/video_picker"
  listView: "VideoList"

  # passed back to the Asset view.
  selectModel: (model) =>
    window.vid = model
    @close()
    @trigger "select", model


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
  template: "assets/asset_uploader"
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

  getCollection: =>
    @collection

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

  getCollection: =>
    @image_collection or @collection


class Cms.Views.VideoUploader extends Cms.Views.AssetUploader
  template: "assets/video_uploader"

  getCollection: =>
    @video_collection or @collection


class Cms.Views.DocumentUploader extends Cms.Views.AssetUploader
  template: "assets/document_uploader"


class Cms.Views.PageAssetUploader extends Cms.View
  template: "assets/page_asset_uploader"


## Asset stylers
#
# These control placement and display of the asset in this setting
# without touching the asset itself or setting any attributes.
#
class Cms.Views.AssetPlacement extends Cms.Views.MenuView
  tagName: "div"
  className: "layout"
  template: "assets/asset_placement"

  events: 
    "click @ui.head": "toggleMenu"
    "click @ui.closer": "close"
    "click a.placement": "setPlacement"

  onRender: =>
    super
    if @model
      @$el.show()
    else
      @$el.hide()

  setModel: (model) =>
    @model = model
    @render()

  setPlacement: (e) =>
    e.preventDefault()
    $el = $(e.currentTarget)
    @log "🚜 setPlacement", $el.data('placement')
    if placement = $el.data('placement')
      @trigger "place", placement
      @close()

