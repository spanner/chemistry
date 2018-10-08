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
    @_default_title = opts.title or t('headings.builder')
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

  saveAndMoveOn: =>
    @log "saveAndMoveOn"
    @model.save().done =>
      #todo: get some swishy transition in here?
      if next_step = _.result @, 'nextStep'
        _cms.navigate next_step
      else
        _cms.navigate @_backto


class Cms.Views.PageBuilderTitle extends Cms.Views.PageBuilderView
  sectionEditor: "SectionTitle"
  nextStep: "image"


class Cms.Views.PageBuilderImage extends Cms.Views.PageBuilderView
  sectionEditor: "SectionImage"
  nextStep: "body"


class Cms.Views.PageBuilderBody extends Cms.Views.PageBuilderView
  sectionEditor: "SectionBody"
  sectionType: "standard"
  nextStep: "social"


class Cms.Views.PageBuilderSocial extends Cms.Views.PageBuilderView
  template: "builder/social"


class Cms.Views.PageBuilderSectionView extends Cms.ItemView
  tagName: "div"
  className: "section"

  triggers:
    "click a.continue": "continue"

  onRender: =>
    @stickit()


class Cms.Views.SectionTitle extends Cms.Views.PageBuilderSectionView
  template: "builder/title"
  bindings:
    ".title": "title"


class Cms.Views.SectionImage extends Cms.Views.PageBuilderSectionView
  template: "builder/image"
  onRender: =>
    # get me the bg view in here


class Cms.Views.SectionBody extends Cms.Views.PageBuilderSectionView
  template: "builder/body"
  bindings:
    ".body": "primary_html"

