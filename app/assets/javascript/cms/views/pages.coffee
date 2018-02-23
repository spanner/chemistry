class Cms.Views.Page extends Cms.View
  template: "cms/page"

  ui:
    sections: "#sections"

  bindings:
    "h1.pagetitle":
      observe: "title"

  onRender: =>
    @stickit()
    @addView new Cms.Views.Sections
      collection: @model.sections
      el: @ui.sections


class Cms.Views.ListedPage extends Cms.View
  template: "cms/listed_page"

  bindings:
    ".title":
      observe: "title"
    "a.page":
      observe: "id"
      onGet: "editMeHref"


class Cms.Views.NoPage extends Cms.View
  template: "cms/no_page"


class Cms.Views.Pages extends Cms.CollectionView
  childView: Cms.Views.ListedPage
  emptyView: Cms.Views.NoPage
  tagName: "ul"
  className: "pages"


class Cms.Views.PagesIndex extends Cms.View
  template: "cms/pages"
  childView: Cms.Views.ListedPage
  childViewContainer: "#pages"

  ui:
    pages: "#pages"

  onRender: =>
    @addView new Cms.Views.Pages
      collection: @collection
      el: @ui.pages

