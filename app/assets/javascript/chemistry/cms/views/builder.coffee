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
    window.page = @model
    @showTitle()
    @ui.closer.attr 'href', @_backto
    @model.sections.loadAnd =>
      @chooseSection()
      @showSectionEditor()

  showTitle: =>
    if section_title = _.result @, 'sectionTitle'
      @ui.title.text t(section_title)
    else
      @ui.title.text @_default_title

  chooseSection: =>
    if section_type_slug = _.result @, 'sectionType'
      @section = @model.sections.where(section_type_slug: section_type_slug).first()
    else
      @section = @model.sections.first()
    window.section = @section

  showSectionEditor: =>
    section_editor = _.result @, 'sectionEditor'
    if section_editor_class = Cms.Views[section_editor]
      @editor = new section_editor_class
        model: @section
      @showChildView 'builder', @editor
      @editor?.on "continue", @saveAndMoveOn
      @editor?.on "goback", @saveAndGoBack

  saveAndGoBack: =>
    @log "saveAndGoBack"
    @model.save().done =>
      if prev_step = _.result @, 'previousStep'
        _cms.navigate prev_step
      else
        _cms.navigate @_backto

  saveAndMoveOn: =>
    @log "saveAndMoveOn"
    @model.save().done =>
      if next_step = _.result @, 'nextStep'
        _cms.navigate next_step
      else
        _cms.navigate @_backto


class Cms.Views.PageBuilderTitle extends Cms.Views.PageBuilderView
  sectionEditor: "SectionTitle"
  nextStep: "asset"


class Cms.Views.PageBuilderAsset extends Cms.Views.PageBuilderView
  sectionEditor: "SectionAsset"
  previousStep: "title"
  nextStep: "body"


class Cms.Views.PageBuilderBody extends Cms.Views.PageBuilderView
  sectionEditor: "SectionBody"
  sectionType: "standard"
  previousStep: "asset"
  nextStep: "social"


class Cms.Views.PageBuilderSocial extends Cms.Views.PageBuilderView
  template: "builder/social"
  previousStep: "body"


class Cms.Views.PageBuilderSectionView extends Cms.ItemView
  tagName: "div"
  className: "section"

  triggers:
    "click a.continue": "continue"
    "click a.back": "goback"

  onRender: =>
    @stickit()


class Cms.Views.SectionTitle extends Cms.Views.PageBuilderSectionView
  template: "builder/title"
  bindings:
    ".title": "title"


class Cms.Views.SectionAsset extends Cms.Views.PageBuilderSectionView
  template: "builder/asset"

  ui:
    asset_holder: ".editing"

  onRender: =>
    @ui.asset_holder.html @model.get('background_html')
    @addView new Cms.Views.EditableBackground
      model: @model
      el: @ui.asset_holder


class Cms.Views.SectionBody extends Cms.Views.PageBuilderSectionView
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
