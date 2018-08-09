# Page-editing view
#
class Cms.Views.Page extends Cms.View
  template: "pages/page"
  tagName: "article"

  regions:
    sections:
      el: ".cms-sections"
    config:
      el: "#config"
      regionClass: Cms.FloatingRegion

  ui:
    sections: ".cms-sections"

  bindings:
    ":el":
      attributes: [
        name: "class"
        observe: "template"
        onGet: "templateSlug"
      ]

  onRender: =>
    window.p = @model
    @stickit()
    @model.sections.loadAnd =>
      @getRegion('sections').show new Cms.Views.Sections
        page: @model
        collection: @model.sections

  templateSlug: (template) =>
    template.get('slug') if template


class Cms.Views.PageRenderer extends Cms.Views.Page
  template: "pages/rendered_page"

  onRender: =>
    @model.sections.loadAnd =>
      @getRegion('sections').show new Cms.Views.RenderedSections
        page: @model
        collection: @model.sections
    rendered = @ui.sections.html()
    @log "rendered", rendered
    @model.set 'rendered_html', rendered


# Main page list
#
class Cms.Views.ListedPage extends Cms.Views.ListedView
  template: "pages/page_listed"
  className: "page"

  ui:
    link: "a.page"
    deleter: "a.delete"

  triggers:
    "click a.config": "config"
    "click a.add.child": "beget"

  bindings:
    ":el":
      attributes: [
        name: "class"
        observe: "content"
      ]
    ".title":
      observe: "title"
      onGet: "shortTitle"
    ".summary":
      observe: "summary"
      onGet: "shortSummary"
    "use.template":
      attributes: [
        name: "xlink:href"
        observe: ["content", "template"]
        onGet: "templateSymbol"
      ]
    "a.page":
      attributes: [
        name: "href"
        observe: ["id", "content", "external_url", "file_url"]
        onGet: "pageHref"
      ]
    "a.delete":
      classes:
        unavailable: "home"

  onRender: =>
    super
    if @ui.deleter.length
      new Cms.Views.Deleter
        model: @model
        el: @ui.deleter

  onReady: =>
    @bindUIElements()
    balanceText('span.title')
    if @model.get('content') is 'page'
      @ui.link.removeAttr('target')
    else
      @ui.link.attr('target', "_blank")

  templateSymbol: ([content, template]=[]) =>
    if content is 'page'
      slug = template?.get('slug') or 'empty'
    else
      slug = content
    "##{slug}_page_symbol"

  shortTitle: (title) =>
    @shortAndClean(title, 48)

  shortSummary: (summary) =>
    @shortAndClean(summary, 96)


class Cms.Views.TreePage extends Cms.Views.ListedPage
  template: "pages/page_in_tree"

  triggers:
    "click a.config": "config"
    "click a.add.child": "beget"

  extraBindings:
    ".indent":
      attributes: [
        name: "style"
        observe: "depth"
        onGet: "indentStyle"
      ]

  indentStyle: (depth) =>
    "width: #{depth * 8}%"


class Cms.Views.ContentsPage extends Cms.Views.ListedPage
  template: "pages/page_in_contents"

  shortTitle: (title) =>
    @shortAndClean(title, 64)

  shortSummary: (summary) =>
    @shortAndClean(summary, 128)


class Cms.Views.NoPage extends Cms.View
  template: "pages/no_page"
  tagName: "li"
  className: "page new"


class Cms.Views.Pages extends Cms.CollectionView
  childView: Cms.Views.ListedPage
  tagName: "ul"
  className: "pages"

  onChildviewConfig: (view) =>
    @trigger "config", view.model

  onChildviewBeget: (view) =>
    @trigger "beget", view.model


class Cms.Views.PageTree extends Cms.Views.Pages
  childView: Cms.Views.TreePage


class Cms.Views.ChildPages extends Cms.Views.Pages
  childView: Cms.Views.ContentsPage
  tagName: "ul"
  className: "contents"


class Cms.Views.PagesIndex extends Cms.Views.IndexView
  template: "pages/index"

  regions:
    pages:
      el: "#pages"

  ui:
    new_page_link: "li.new.page"
    new_page_title: "span.title"
    new_page_description: "span.description"

  events:
    "click a.new.page": "startNewPage"

  onRender: =>
    super
    if @collection.size()
      @ui.new_page_title.text t('pages.new_title')
    else 
      @ui.new_page_title.text t('pages.new_home_title')

    page_tree = new Cms.Views.PageTree
      collection: @collection
    page_tree.on "beget", @startChildPage
    page_tree.on "config", @configPage
    @getRegion('pages').show page_tree

  startNewPage: (e) =>
    @containEvent(e)
    new_page_view = if @collection.size() then new Cms.Views.NewPage else new Cms.Views.NewHomePage
    _cms.ui.floatView new_page_view,
      over: @ui.new_page_link

  startChildPage: (model) =>
    new_page_view = new Cms.Views.NewPage
      parent: model
    _cms.ui.floatView new_page_view,
      over: @ui.new_page_link

  configPage: (model) =>
    config_page_view = new Cms.Views.ConfigPage
      model: model
    _cms.ui.floatView config_page_view,
      over: @ui.new_page_link


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
  template: "helpers/pick_parent"

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


## Page metadata editors
#
# Used to modify existing or create new pages.
#
class Cms.Views.ConfigPage extends Cms.Views.FloatingView
  template: "pages/config_page"

  regions:
    parent: ".parent_picker"
    content: ".content_picker"
    keywords: ".terms_picker"
    dates: ".dates_picker"

  events:
    "click a.save": "saveAndClose"

  ui:
    "savebutton": "a.save"

  bindings:
    "span.title":
      observe: "title"
      classes:
        valid:
          observe: "title"
          onGet: "ifPresent"
    "span.summary":
      observe: "summary"
    "a.save":
      classes:
        available:
          observe: ['template_id', 'title']
          onGet: "thisAndThat"

  initialize: (options={}) ->
    window.p = @model
    unless @model
      @model = new Cms.Models.Page
      @model.set 'parent', options.parent
    super

  onRender: =>
    @stickit()
    @getRegion('parent').show new Cms.Views.ParentPagePicker
      model: @model
    @getRegion('content').show new Cms.Views.ContentPicker
      model: @model
    @getRegion('keywords').show new Cms.Views.TermsPicker
      model: @model
    @getRegion('dates').show new Cms.Views.DatesPicker
      model: @model

  saveAndEdit: (e) =>
    @containEvent(e)
    @model.save().done =>
      if id = @model.get('id')
        @trigger 'close'
        _cms.pages.add @model
        if @model.get('content') is 'page'
          _cms.navigate "/#{@model.singularName()}/edit/#{id}"

  saveAndClose: (e) =>
    @containEvent(e)
    @model.save().done =>
      @trigger 'close'


class Cms.Views.NewPage extends Cms.Views.ConfigPage
  template: "pages/new_page"
  events:
    "click a.save": "saveAndEdit"


class Cms.Views.NewHomePage extends Cms.Views.NewPage
  template: "pages/new_home_page"

