class Cms.Views.ContentPicker extends Cms.View
  template: "helpers/pick_content"

  regions:
    template: ".template_picker"
    file: ".file_picker"
    image: ".image_picker"
    video: ".video_picker"
    url: ".url_picker"

  bindings:
    'input[name="content"]':
      observe: "content"
    '.if_page':
      observe: "content"
      visible:  (content) -> content is 'page'
    '.if_file':
      observe: "content"
      visible:  (content) -> content is 'file'
    '.if_image':
      observe: "content"
      visible: (content) -> content is 'image'
    '.if_video':
      observe: "content"
      visible:  (content) -> content is 'video'
    '.if_url':
      observe: "content"
      visible:  (content) -> content is 'url'

  onRender: =>
    @stickit()
    @getRegion('template').show new Cms.Views.TemplatePicker
      model: @model
    @getRegion('file').show new Cms.Views.PageDocumentPicker
      model: @model
      collection: new Cms.Collections.Documents
    @getRegion('image').show new Cms.Views.PageImagePicker
      model: @model
      collection: new Cms.Collections.Images
    @getRegion('video').show new Cms.Views.PageVideoPicker
      model: @model
      collection: new Cms.Collections.Videos
    @getRegion('url').show new Cms.Views.UrlPicker
      model: @model


class Cms.Views.TermsPicker extends Cms.View
  template: "helpers/pick_terms"

  ui:
    keywords: 'input.keywords'

  bindings:
    "input.keywords":
      observe: "keywords"

  onRender: =>
    @initTokenInput()
    @stickit()

  initTokenInput: =>
    if terms = @model.get('keywords')
      existing_terms = _.map _.uniq(terms.split(',')), (t) -> name: t
    else
      existing_terms = []

    url = [_cms.config('api_url'), 'terms'].join('/')
    @ui.keywords.tokenInput url,
      minChars: 2
      tokenValue: "name"
      placeholder: "Keywords"
      prePopulate: existing_terms
      excludeCurrent: true
      allowFreeTagging: true
      hintText: t("notes.term_search_hint")
      onDelete: () ->
        @trigger 'input'
      onAdd: () ->
        @trigger 'input'
      onResult: (data) ->
        seen = {}
        terms = []
        data = data.data if data.data
        _.map data, (datum) ->
          term = datum.attributes.term
          unless seen[term]
            terms.push(name: term)
            seen[term] = true
        terms
    @_search_field = @$el.find('li.token-input-input-token input[type="text"]')
    @_search_field.attr "placeholder", @ui.keywords.attr('placeholder')

  focus: =>
    @_search_field?.focus()



class Cms.Views.DatesPicker extends Cms.View
  template: "helpers/pick_dates"

  ui:
    dates: 'span.dates'

  onRender: =>
    @stickit()
    model = @model
    if model.get('began_at') and model.get('ended_at')
      @ui.dates.text [model.get('began_at'), model.get('ended_at')].join(' to ')
    @ui.dates.dateRangePicker
      monthSelect: true
      yearSelect: true
      autoClose: true
      singleDate : false
      singleMonth: false
      showShortcuts: false
      showTopbar: false
      getValue: () ->
        @innerHTML
      setValue: (s, d1, d2) -> 
        model.set
          began_at: d1
          ended_at: d2
        @innerHTML = s


class Cms.Views.UrlPicker extends Cms.View
  template: "helpers/pick_url"
  tagName: "p"

  bindings:
    "span.url": "external_url"


class Cms.Views.PageAssetPicker extends Cms.CompositeView
  template: "assets/pick_page_asset"
  childView: Cms.Views.ListedAsset
  emptyView: Cms.Views.NoAsset
  childViewContainer: "ul.cms-assets"

  events:
    "child:select": "setModel"

  ui:
    upload: "li.upload"

  initialize: ->
    @collection.load()

  onRender: =>
    unless @_upload_view
      @_upload_view = new Cms.Views.PageAssetUploader
        collection: @collection
      @ui.upload.append @_upload_view.el
      @_upload_view.on "create", @setModel
    @_upload_view.render()

  setModel: (model) =>
    @trigger "select", model


class Cms.Views.PageImagePicker extends Cms.Views.PageAssetPicker


class Cms.Views.PageVideoPicker extends Cms.Views.PageAssetPicker


class Cms.Views.PageDocumentPicker extends Cms.Views.PageAssetPicker
  childView: Cms.Views.ListedDocument


















class Cms.Views.PageFilePicker extends Cms.PageAssetPicker
  template: "helpers/page_file"

  bindings:
    "span.url": "external_url"

  onRender: =>
    @stickit()
