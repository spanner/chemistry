class Cms.Views.Section extends Cms.View
  tagName: "section"

  className: => @model?.get('section_type_slug')

  template: => @model?.getTemplate()

  ui:
    title: '[data-cms-role="title"]'
    primary: '[data-cms-role="primary"]'
    secondary: '[data-cms-role="secondary"]'
    editable: '[data-cms-editor="full"]'

  bindings:
    ":el":
      class:
        deleted: "deleted_at"
      attributes: [
        name: "id"
        observe: "id"
        onGet: "sectionId"
      ]
    '[data-cms-role="title"]':
      observe: "title"
      updateMethod: "html"
    '[data-cms-role="primary"]':
      observe: "primary_html"
      updateMethod: "html"
    '[data-cms-role="secondary"]':
      observe: "secondary_html"
      updateMethod: "html"

  initialize: (opts={}) =>
    super
    @page = opts.page
    @model.on "change:section_type", @render

  onRender: =>
    @ui.title.attr('contenteditable', 'plaintext-only')
    @ui.primary.attr('contenteditable', 'true').addClass('editing')
    @ui.secondary.attr('contenteditable', 'true').addClass('editing')
    @ui.primary.on('focus', @ensureP).on('blur', @clearP)
    @ui.secondary.on('focus', @ensureP).on('blur', @clearP)
    @setDefaults()
    @setPlaceholders()
    super
    @addEditor()

  sectionId: (id) -> 
    "section_#{id}"

  setDefaults: =>
    slug = @model.get('section_type_slug')
    if slug is 'hero' or slug is 'standfirst'
      @log "setDefaults", @model.get('section_type_slug'), @page.get('title')
      @model.set('title', @page?.get('title')) unless @model.get('title')

  setPlaceholders: =>
    if slug = @model.get('section_type_slug')
      for att in ['title', 'primary', 'secondary', 'caption']
        if _cms.translationAvailable("placeholders.sections.#{slug}.#{att}")
          title = t("placeholders.sections.#{slug}.#{att}")
        else if _cms.translationAvailable("placeholders.sections.#{att}")
          title = t("placeholders.sections.#{att}")
        @log "setPlaceholders", att, slug, "->", title
        if title
          @$el.find('[data-cms-role="' + att + '"]').attr('data-placeholder', title)

  addEditor: =>
    @ui.editable.each (i, el) =>
      @log "addEditor", el
      @addView new Cms.Views.Editor
        model: @model
        el: el

  ensureP: (e) =>
    el = e.target
    if el.innerHTML is ""
      el.style.minHeight = el.offsetHeight + 'px'
      p = document.createElement('p')
      p.innerHTML = "&#8203;"
      el.appendChild p

  clearP: (e) =>
    el = e.target
    content = el.innerHTML
    el.innerHTML = "" if content is "<p>&#8203;</p>" or content is "<p><br></p>" or content is "<p>​</p>"  # there's a zwsp in that last string



class Cms.Views.NoSection extends Cms.View
  template: "no_section"


class Cms.Views.Sections extends Cms.Views.AttachedCollectionView
  childView: Cms.Views.Section
  emptyView: Cms.Views.NoSection
  # nb AttachedCollectionView is self-loading and self-rendering

  childViewOptions: (model) =>
    page: @page

  initialize: (opts={}) =>
    @page = opts.page
    super


