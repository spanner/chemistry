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
    super
    @_default_title = opts.title or t('headings.builder.default')
    @_backto = opts.backto

  onSubmit: (e) =>
    e?.preventDefault()

  onRender: =>
    @showTitle()
    @ui.closer.attr 'href', @_backto
    @model.sections.loadAnd =>
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

  showEditor: =>
    editor = _.result @, 'sectionEditor'
    if editor_class = Cms.Views[editor]
      @editor = new editor_class
        model: @edited_model
      @showChildView 'builder', @editor
      @editor?.on "continue", @saveAndMoveOn
      @editor?.on "goback", @saveAndGoBack

  saveAndGoBack: =>
    @model.save().done =>
      if prev_step = _.result @, 'previousStep'
        _cms.navigate prev_step
      else
        window.location.href = @_backto

  saveAndMoveOn: =>
    @model.save().done =>
      if next_step = _.result @, 'nextStep'
        _cms.navigate next_step
      else
        window.location.href = @_backto


class Cms.Views.PageBuilderTitle extends Cms.Views.PageBuilderView
  sectionEditor: "SectionTitle"
  nextStep: "asset"
  sectionTitle: =>
    t('headings.builder.title')


class Cms.Views.PageBuilderAsset extends Cms.Views.PageBuilderView
  sectionEditor: "SectionAsset"
  previousStep: "title"
  nextStep: "body"
  sectionTitle: =>
    t('headings.builder.asset')


class Cms.Views.PageBuilderBody extends Cms.Views.PageBuilderView
  sectionEditor: "SectionBody"
  sectionType: "standard"
  previousStep: "asset"
  nextStep: "social"
  sectionTitle: =>
    t('headings.builder.body')


class Cms.Views.PageBuilderSocial extends Cms.Views.PageBuilderView
  sectionEditor: "PageSocials"
  previousStep: "body"
  nextStep: "preview"
  sectionEditor: "PageSocials"

  sectionTitle: =>
    t('headings.builder.social')

  chooseModel: =>
    @edited_model = @model


class Cms.Views.PageBuilderPreview extends Cms.Views.PageBuilderView
  sectionEditor: "PagePreview"
  previousStep: "social"
  sectionEditor: "PageSocials"

  sectionTitle: =>
    t('headings.builder.preview')

  chooseModel: =>
    @edited_model = @model


class Cms.Views.PageBuilderSubView extends Cms.ItemView
  tagName: "div"
  className: "section"

  ui:
    holder: ".editing"

  triggers:
    "click a.continue": "continue"
    "click a.back": "goback"

  onRender: =>
    @log "render", @model.attributes
    @stickit()


class Cms.Views.SectionTitle extends Cms.Views.PageBuilderSubView
  template: "builder/title"
  bindings:
    ".title": "title"


class Cms.Views.SectionAsset extends Cms.Views.PageBuilderSubView
  template: "builder/asset"

  onRender: =>
    @ui.holder.html @model.get('background_html')
    @addView new Cms.Views.EditableBackground
      model: @model
      el: @ui.holder


class Cms.Views.SectionBody extends Cms.Views.PageBuilderSubView
  template: "builder/body"
  bindings:
    ".body":
      observe: "primary_html"
      updateMethod: "html"
      onSet: "withoutControls"

  ui:
    section_body: ".body"

  onRender: =>
    @stickit()
    @addView new Cms.Views.EditableHtml
      model: @model
      el: @ui.section_body


class Cms.Views.PageSocials extends Cms.Views.PageBuilderSubView
  template: "builder/socials"

  ui:
    socials: "div.socialist"

  onRender: =>
    @addView new Cms.Views.SocialsManager
      model: @model
      el: @ui.socials

