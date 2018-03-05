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






class Cms.Views.TemplateChoice extends Cms.Views.ChoiceView
  template: "cms/template_choice"
  tagName: "li"
  className: "template choice"
  bindings:
    ".title":
      observe: "title"
    "img":
      attributes: [
        name: "src"
        observe: "icon_url"
        onGet: "iconOrDefault"
      ]
    "a.choose":
      attributes: [
        name: "title"
        observe: "description"
      ]
      classes:
        chosen: "chosen"

  iconOrDefault: (icon_url) =>
    icon_url if icon_url


class Cms.Views.NoTemplateChoice extends Cms.Views.ChoiceView
  template: "cms/no_template_choice"
  tagName: "li"
  className: "template choice new"


class Cms.Views.TemplatePicker extends Cms.Views.ChooserView
  childView: Cms.Views.TemplateChoice
  emptyView: Cms.Views.NoTemplateChoice
  tagName: "ul"
  className: "template picker"

  initialize: ->
    @collection = _cms.templates.clone()
    @render()

  choose: (template) =>
    @model.set 'template', template
