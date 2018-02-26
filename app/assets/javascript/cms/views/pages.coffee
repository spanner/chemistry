class Cms.Views.Page extends Cms.View
  template: "cms/page"

  ui:
    sections: "#sections"

  bindings:
    "h1.pagetitle":
      observe: "title"

  onRender: =>
    @log "Pages render"
    @stickit()
    @addView new Cms.Views.Sections
      collection: @model.sections
      el: @ui.sections


class Cms.Views.ListedPage extends Cms.View
  template: "cms/listed_page"
  tagName: "li"
  className: "page"

  bindings:
    ".title":
      observe: "title"
    "a.page":
      observe: "id"
      onGet: "editMeHref"


class Cms.Views.NoPage extends Cms.View
  template: "cms/no_page"
  tagName: "li"
  className: "page new"


class Cms.Views.Pages extends Cms.CollectionView
  childView: Cms.Views.ListedPage
  emptyView: Cms.Views.NoPage
  tagName: "ul"
  className: "pages"


class Cms.Views.PagesIndex extends Cms.IndexView
  template: "cms/pages"

  onRender: =>
    super
    @getRegion('list').show new Cms.Views.Pages
      collection: @collection

