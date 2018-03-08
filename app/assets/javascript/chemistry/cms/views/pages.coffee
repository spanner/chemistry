# Page-editing view
#
class Cms.Views.Page extends Cms.View
  template: "page"

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
class Cms.Views.ListedPage extends Cms.Views.ListedView
  template: "page_listed"
  className: "page"

  ui:
    deleter: "a.delete"

  bindings:
    ".title":
      observe: "title"
    ".indent":
      attributes: [
        name: "style"
        observe: "depth"
        onGet: "indentStyle"
      ]
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
    "a.delete":
      classes:
        unavailable: "home"

  onRender: =>
    super
    if @ui.deleter.length
      new Cms.Views.Deleter
        model: @model
        el: @el


  templateIconOrDefault: (template) =>
    template?.get('icon_url')

  indentStyle: (depth) =>
    "width: #{depth * 48}px"


class Cms.Views.TreePage extends Cms.Views.ListedPage
  template: "page_in_tree"


class Cms.Views.NoPage extends Cms.View
  template: "no_page"
  tagName: "li"
  className: "page new"


class Cms.Views.Pages extends Cms.CollectionView
  childView: Cms.Views.ListedPage
  tagName: "ul"
  className: "pages"


class Cms.Views.PageTree extends Cms.CollectionView
  childView: Cms.Views.TreePage
  tagName: "ul"
  className: "pages tree"


class Cms.Views.PagesIndex extends Cms.Views.IndexView
  template: "pages"

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
    @getRegion('pages').show new Cms.Views.PageTree
      collection: @collection

  startNewPage: (e) =>
    e.preventDefault()
    e.stopPropagation()
    $link = $(e.currentTarget)
    new_page_view = if @collection.size() then new Cms.Views.NewPage else new Cms.Views.NewHomePage
    @getRegion('new_page').show new_page_view, over: $link


# Page choosers
#
class Cms.Views.PageOption extends Cms.Views.ModelOption
  template: false
  tagName: "option"

  titleOrDefault: (title) =>
    depth = @model.get('depth')
    prefix = "&nbsp;&nbsp;&nbsp;&nbsp;".repeat depth
    prefix + super


class Cms.Views.PageSelect extends Cms.Views.CollectionSelect
  className: "pages chooser"
  attribute: "page_id"
  childView: Cms.Views.PageOption

  initialize: ->
    @collection = _cms.pages.clone()
    super


class Cms.Views.ParentPageSelect extends Cms.Views.PageSelect
  attribute: "parent"
  allowBlank: true


class Cms.Views.ParentPagePicker extends Cms.View
  template: "parent_picker"

  ui:
    select: "select"

  bindings:
    "p":
      classes:
        absent:
          observe: "parent"
          onGet: "ifAbsent"
        valid:
          observe: "parent"
          onGet: "ifPresent"

  onRender: =>
    @stickit()
    new Cms.Views.ParentPageSelect
      model: @model
      el: @ui.select

  parentTitle: (parent) =>
    if parent
      parent.get('title')
    else
      ""


# The transient view used to inject a new page into the tree and prepare it for editing.
#
class Cms.Views.NewPage extends Cms.Views.FloatingView
  template: "new_page"

  regions:
    parent: ".parent_picker"
    template: ".template_picker"

  events:
    "click a.save": "saveAndEdit"

  bindings:
    "span.title":
      observe: "title"
      classes:
        valid:
          observe: "title"
          onGet: "ifPresent"
    "a.save":
      classes:
        available:
          observe: ['template_id', 'title']
          onGet: "thisAndThat"

  initialize: ->
    @model = new Cms.Models.Page
    window.np = @model
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
      if id = @model.get('id')
        @trigger 'close'
        _cms.pages.add @model
        _cms.navigate "/#{@model.pluralName()}/edit/#{id}"


class Cms.Views.NewHomePage extends Cms.Views.NewPage
  template: "new_home_page"
  regions:
    template: ".template_picker"
