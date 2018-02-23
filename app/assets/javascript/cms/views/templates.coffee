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