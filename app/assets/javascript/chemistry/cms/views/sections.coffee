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

  initialize: =>
    super
    @model.on "change:section_type", @render

  onRender: =>
    @ui.title.attr('contenteditable', 'plaintext-only')
    @ui.primary.attr('contenteditable', 'true')
    @ui.secondary.attr('contenteditable', 'true')
    @ui.primary.on('focus', @ensureP).on('blur', @clearP)
    @ui.secondary.on('focus', @ensureP).on('blur', @clearP)
    @setPlaceholders()
    super
    @addEditor()

  sectionId: (id) -> 
    "section_#{id}"

  setPlaceholders: =>
    @log "setPlaceholders", @model.get('section_type_slug')
    if slug = @model.get('section_type_slug')
      for att in ['title', 'primary', 'secondary']
        if _cms.translationAvailable("placeholders.sections.#{slug}.#{att}")
          @$el.find('[data-cms-role="' + att + '"]').attr('data-placeholder', t("placeholders.sections.#{slug}.#{att}"))

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
