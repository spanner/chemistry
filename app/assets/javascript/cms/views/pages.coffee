# Page-editing view
#
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


# Main page list
#
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
    pages:
      el: "#pages"
    new_page:
      el: "#new_page"
      regionClass: Cms.FloatingRegion

  ui:
    new_page_title: "span.title"
    new_page_description: "span.description"

  events:
    "click a.new.page": "startNewPage"

  onRender: =>
    super
    if @collection.size()
      @ui.new_page_title.text("Create new page")
    else 
      @ui.new_page_title.text("Create home page")
    @getRegion('pages').show new Cms.Views.Pages
      collection: @collection

  startNewPage: (e) =>
    e.preventDefault()
    e.stopPropagation()
    $link = $(e.currentTarget)
    new_page_view = if @collection.size() then new Cms.Views.NewPage else new Cms.Views.NewHomePage
    @getRegion('new_page').show new_page_view,
      over: $link


# Page-chooser
#
class Cms.Views.PageChoice extends Cms.View
  template: "cms/page_choice"
  tagName: "li"
  className: "page choose"

  bindings:
    ".title":
      observe: "title"
    ".path":
      observe: "path"


class Cms.Views.NoPageChoice extends Cms.View
  template: "cms/no_page_choice"
  tagName: "li"
  className: "page choose none"


class Cms.Views.PagePicker extends Cms.CollectionView
  childView: Cms.Views.PageChoice
  emptyView: Cms.Views.NoPageChoice
  tagName: "ul"
  className: "pages chooser"


# The transient view used to inject a new page into the tree and prepare it for editing.
#
class Cms.Views.NewPage extends Cms.View
  template: "cms/new_page"

  ui:
    parent: ".parent_picker"
    templates: ".template_picker"
    title: "span.title"
    introduction: "span.description"

  bindings:
    ".title": "title"

  initialize: ->
    @model = new Cms.Models.Page
    super

  onRender: =>
    @log "render"
    @stickit()
    @addView new Cms.Views.TemplatePicker
      collection: _cms.templates
      el: @ui.templates
    @addView new Cms.Views.PagePicker
      collection: _cms.pages
      el: @ui.parent
    @$el.addClass 'up'


class Cms.Views.NewHomePage extends Cms.View
  template: "cms/new_home_page"
