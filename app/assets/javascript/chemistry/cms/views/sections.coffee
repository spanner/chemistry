class Cms.Views.Section extends Cms.View
  tagName: "section"

  className: => @model?.get('section_type_slug')

  template: => @model?.getTemplate()

  bindings:
    ":el":
      class:
        deleted: "deleted_at"
      attributes: [
        name: "id"
        observe: "id"
        onGet: "sectionId"
      ]
    '[data-role="title"]':
      observe: "title"
    '[data-role="primary"]':
      observe: "primary_html"
      updateMethod: "html"
    '[data-role="secondary"]':
      observe: "secondary_html"
      updateMethod: "html"

  initialize: =>
    super
    @model.on "change:section_type", @render

  onRender: =>
    @$el.find('[data-role="title"]').attr('contenteditable', 'plaintext-only')
    @$el.find('[data-role="primary"]').attr('contenteditable', 'true')
    @$el.find('[data-role="secondary"]').attr('contenteditable', 'true')
    @setPlaceholders()
    super

  sectionId: (id) -> 
    "section_#{id}"

  setPlaceholders: =>
    @log "setPlaceholders", @model.get('section_type_slug')
    if slug = @model.get('section_type_slug')
      for att in ['title', 'primary', 'secondary']
        @log "placeholding", att
        @log "placeholder", t("placeholders.sections.#{slug}.#{att}")
        @log "place", @$el.find('[data-role="' + att + '"]')
        @$el.find('[data-role="' + att + '"]').attr('data-placeholder', t("placeholders.sections.#{slug}.#{att}"))


class Cms.Views.NoSection extends Cms.View
  template: "no_section"


class Cms.Views.Sections extends Cms.Views.AttachedCollectionView
  childView: Cms.Views.Section
  emptyView: Cms.Views.NoSection
  # nb AttachedCollectionView is self-loading and self-rendering
