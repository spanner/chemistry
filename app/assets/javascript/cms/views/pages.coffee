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
  template: "cms/page_listed"
  tagName: "li"
  className: "page"

  bindings:
    ".title":
      observe: "title"
    "img.page_icon":
      attributes: [
        name: "src"
        observe: "template"
        onGet: "templateIconOrDefault"
      ]
    "a.page":
      attributes: [
        name: "href"
        observe: "id"
        onGet: "editMeHref"
      ]

  templateIconOrDefault: (template) =>
    template?.get('icon_url')


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
    @getRegion('new_page').show new_page_view, over: $link


# Page-chooser
#
class Cms.Views.PageChoice extends Cms.Views.ChoiceView
  template: "cms/page_choice"
  tagName: "li"
  className: "page choose"

  bindings:
    ".title":
      observe: "title"
    ".path":
      observe: "path"


class Cms.Views.NoPageChoice extends Cms.Views.NoChoiceView
  template: "cms/no_page_choice"
  tagName: "li"
  className: "page choose none"


class Cms.Views.PagePicker extends Cms.Views.ChooserView
  childView: Cms.Views.PageChoice
  emptyView: Cms.Views.NoPageChoice
  tagName: "ul"
  className: "pages chooser"

  initialize: ->
    @collection = _cms.pages.clone()
    @render()

  choose: (page) =>
    @model.set 'page', page


class Cms.Views.ParentPagePicker extends Cms.Views.PagePicker

  choose: (page) =>
    @model.set 'parent', page


# The transient view used to inject a new page into the tree and prepare it for editing.
#
class Cms.Views.NewPage extends Cms.Views.FloatingView
  template: "cms/new_page"

  regions:
    parent: ".parent_picker"
    template: ".template_picker"

  events:
    "click a.save": "saveAndEdit"

  bindings:
    "span.title": "title"
    "a.save":
      classes:
        available:
          observe: ['template_id', 'title']
          onGet: "thisAndThat"

  initialize: ->
    @model = new Cms.Models.Page
    super

  onRender: =>
    @stickit()
    if @regions.template
      @getRegion('template').show new Cms.Views.TemplatePicker
        model: @model
    if @regions.parent
      @getRegion('parent').show new Cms.Views.ParentPagePicker
        model: @model

  saveAndEdit: (e) =>
    e?.preventDefault()
    e?.stopPropagation()
    @model.save().done =>
      _.defer =>
        if id = @model.get('id')
          type = @model.pluralName()
          @remove()
          _cms.navigate "/#{type}/edit/#{id}"


class Cms.Views.NewHomePage extends Cms.Views.NewPage
  template: "cms/new_home_page"
  regions:
    template: ".template_picker"
