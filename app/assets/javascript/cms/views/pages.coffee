class Cms.Views.Page extends Cms.View
  template: "cms/page"

  ui:
    sections: "#sections"

  bindings:
    "h1.pagetitle":
      observe: "title"
    "date":
      observe: "publication_date"

  onRender: =>
    @stickit()
    @addView new Cms.Views.Sections
      collection: @model.sections
      el: @ui.sections