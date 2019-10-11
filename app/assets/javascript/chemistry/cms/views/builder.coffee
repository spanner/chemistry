# Page-editing view
#
class Cms.Views.PageBuilderView extends Cms.ItemView
  template: "builder/builder"
  className: "builder"

  regions:
    builder:
      el: "#builder"
      regionClass: Cms.FadingRegion

  ui:
    title: "h1.builder"
    closer: "a.close"
    builder: "#builder"

  initialize: (opts={}) ->
    super()
    window.p = @model
    @_default_title = opts.title or t('headings.builder.default')
    @_backto = opts.backto

  onSubmit: (e) =>
    e?.preventDefault()

  onRender: =>
    @showTitle()
    @ui.closer.attr 'href', @_backto
    @log "onRender with page", @model.id, @model.cid
    @model.sections.loadAnd =>
      @log "and sections", @model.sections.map((s) -> s.cid)
      @chooseModel()
      @showEditor()

  showTitle: =>
    if section_title = _.result @, 'sectionTitle'
      @ui.title.text t(section_title)
    else
      @ui.title.text @_default_title

  chooseModel: =>
    if section_type_slug = _.result @, 'sectionType'
      @edited_model = @model.sections.findWhere(section_type_slug: section_type_slug)
    else
      @edited_model = @model.sections.first()
    @log "@edited_model", @edited_model.cid
    @edited_model

  showEditor: =>
    editor = _.result @, 'sectionEditor'
    if editor_class = Cms.Views[editor]
      @editor = new editor_class
        model: @edited_model
      @showChildView 'builder', @editor
      @editor?.on "publish", @publishAndFinish
      @editor?.on "continue", @saveAndMoveOn
      @editor?.on "goback", @saveAndGoBack

  saveAndGoBack: (view, e) =>
    prev_step = e?.target.getAttribute('href') or _.result(@, 'previousStep')
    @model.save().done =>
      if prev_step
        _cms.navigate prev_step
      else
        window.location.href = @_backto

  saveAndMoveOn: (view, e) =>
    next_step = e?.target.getAttribute('href') or _.result(@, 'nextStep')
    @model.save().done =>
      if next_step
        _cms.navigate next_step
      else
        window.location.href = @_backto

  publishAndFinish: (e) =>
    @model.publish().done =>
      @log "OK THEN"


## Builder steps
#  each declare a step title and edit view.
#
class Cms.Views.PageBuilderTitle extends Cms.Views.PageBuilderView
  sectionEditor: "SectionTitle"
  nextStep: "asset"
  sectionTitle: => 'headings.builder.title'


class Cms.Views.PageBuilderAsset extends Cms.Views.PageBuilderView
  sectionEditor: "SectionAsset"
  previousStep: "title"
  nextStep: "body"
  sectionTitle: 'headings.builder.asset'


class Cms.Views.PageBuilderBody extends Cms.Views.PageBuilderView
  sectionEditor: "SectionBody"
  sectionType: "standard"     # we edit first standard section on page
  previousStep: "asset"
  nextStep: "social"
  sectionTitle: 'headings.builder.body'


class Cms.Views.PageBuilderSocial extends Cms.Views.PageBuilderView
  sectionEditor: "PageSocials"
  previousStep: "body"
  nextStep: "preview"

  sectionTitle: 'headings.builder.social'

  chooseModel: =>
    @edited_model = @model


class Cms.Views.PageBuilderPreview extends Cms.View
  template: "builder/preview"
  className: "builder"

  regions:
    preview:
      el: "#preview"
      regionClass: Cms.FadingRegion

  ui:
    preview: "#preview"
    publish: "a.publish"
    published: ".published"
    previewed: ".previewed"
    goto: "a.page"

  events:
    "click a.publish": "publish"
    "click a.builder": "goStep"
    "click a.editor": "goStep"

  bindings:
    ".previewed":
      observe: "outofdate"
      visible: true
    ".published":
      observe: "outofdate"
      visible: "untrue"

  onRender: =>
    @stickit()
    @model.sections.loadAnd =>
      @model.socials.loadAnd =>
        @ui.preview.addClass @model.get('template_slug')
        @preview = new Cms.Views.PageRenderer
          model: @model
        @showChildView 'preview', @preview

  goStep: (e) =>
    e?.preventDefault()
    if next_step = e?.target.getAttribute('href')
      _cms.navigate next_step

  publish: (e) =>
    e?.preventDefault()
    @ui.publish.addClass('waiting')
    @model.publish().done @confirm

  confirm: =>
    @ui.goto.attr('href', "/" + @model.get('path'))
    @ui.publish.removeClass('waiting')
    @ui.previewed.slideUp()
    @ui.published.slideDown()


class Cms.Views.PageBuilderEditor extends Cms.View
  template: "builder/editor"
  className: "builder"

  regions:
    buttons: ".buttons"
    editor:
      el: "#editor"
      regionClass: Cms.FadingRegion

  ui:
    editor: "#editor"
    buttons: ".buttons"

  events:
    "click a.back": "goBack"

  onRender: =>
    @model.sections.loadAnd =>
      @model.socials.loadAnd =>
        @ui.editor.addClass @model.get('template_slug')
        @showChildView 'editor', new Cms.Views.PageEditor
          model: @model
        @showChildView 'buttons', new Cms.Views.MiniSaver
          model: @model

  goBack: (e) =>
    e?.preventDefault()
    _cms.navigate ""


## Builder edit views
#  usually choose one section attribute to bind, but may delegate to another editor instead.
#
class Cms.Views.PageBuilderSubView extends Cms.ItemView
  tagName: "div"
  className: "section"

  ui:
    holder: ".editing"

  triggers:
    "click a.publish": "publish"
    "click a.continue": "continue"
    "click a.back": "goback"

  onRender: =>
    @log "render", @model.attributes
    @stickit()


class Cms.Views.SectionTitle extends Cms.Views.PageBuilderSubView
  template: "builder/title"
  className: "section page_title"

  bindings:
    ".title": "title"


class Cms.Views.SectionAsset extends Cms.Views.PageBuilderSubView
  template: "builder/asset"
  className: "section page_asset"

  onRender: =>
    @ui.holder.html @model.get('background_html')
    @addView new Cms.Views.EditableBackground
      model: @model
      el: @ui.holder


class Cms.Views.SectionBody extends Cms.Views.PageBuilderSubView
  template: "builder/body"
  className: "section page_body"

  ui:
    section_body: ".body"

  bindings:
    ".body":
      observe: "primary_html"
      updateMethod: "html"
      onSet: "withoutControls"

  onRender: =>
    @stickit()
    @addView new Cms.Views.EditableHtml
      model: @model
      el: @ui.section_body


class Cms.Views.PageSocials extends Cms.Views.PageBuilderSubView
  template: "builder/socials"
  className: "section page_socials"

  ui:
    socials: "div.socialist"

  onRender: =>
    @addView new Cms.Views.SocialsManager
      model: @model
      el: @ui.socials


