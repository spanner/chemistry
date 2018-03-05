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
  tagName: "ul"
  className: "pages"


class Cms.Views.PagesIndex extends Cms.IndexView
  template: "cms/pages"

  regions:
    pages: "#pages"
    new_page: "#new_page"

  ui:
    new_page_title: "span.title"
    new_page_description: "span.description"

  events:
    "click a.new.page": "startNewPage"

  onRender: =>
    super
    if @collection.size()
      @ui.new_page_title = "Create new page"
    else 
      @ui.new_page_title = "Create home page"
    @getRegion('pages').show new Cms.Views.Pages
      collection: @collection

  startNewPage: (e) =>
    e.preventDefault()
    e.stopPropagation()
    $link = $(e.currentTarget)
    @getRegion('new_page').show new Cms.Views.NewPage
    # place modal form over triggering link


# The transient view used to inject a new page into the tree and prepare it for editing.
#
class Cms.Views.NewPage extends Cms.View
  template: "cms/new_page"

  ui:
    parent: ".parent_picker"
    templates: ".template_picker"

  bindings:
    ".title": "title"

  onRender: =>
    @log "NewPage render"
    @stickit()
    @addView new Cms.Views.TemplatePicker
      collection: _cms.templates
      el: @ui.templates
    @addView new Cms.Views.ParentPagePicker
      collection: _cms.pages
      el: @ui.parent


