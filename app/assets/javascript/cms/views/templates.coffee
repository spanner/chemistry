class Cms.Views.Template extends Cms.View
  template: "cms/template"

  ui:
    placeholders: "#placeholders"

  bindings:
    "h1.pagetitle":
      observe: "title"

  onRender: =>
    @stickit()
    @addView new Cms.Views.Placeholders
      collection: @model.placeholders
      el: @ui.placeholders


class Cms.Views.ListedTemplate extends Cms.View
  template: "cms/listed_template"
  bindings:
    ".title": "title"
    ".description": "description"


class Cms.Views.TemplateChoice extends Cms.Views.ListedTemplate
  template: "cms/template_choice"


class Cms.Views.TemplatePicker extends Cms.CollectionView
  childView: Cms.Views.TemplateChoice
  emptyView: Cms.Views.NoTemplateChoice
