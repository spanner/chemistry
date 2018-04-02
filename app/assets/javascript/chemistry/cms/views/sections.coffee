class Cms.Views.Section extends Cms.View
  tagName: "section"

  className: => @model?.get('section_type_slug')

  template: => @model?.getTemplate()

  ui:
    editable: '[data-cms-editor]'
    editable_background_image: '[data-cms-editor="bg"]'
    editable_html: '[data-cms-editor="html"]'
    editable_string: '[data-cms-editor="string"]'

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
      onSet: "withoutHTML"
    '[data-cms-role="primary"]':
      observe: "primary_html"
      updateMethod: "html"
      onSet: "withoutControls"
    '[data-cms-role="secondary"]':
      observe: "secondary_html"
      updateMethod: "html"
      onSet: "withoutControls"

  initialize: (opts={}) =>
    super
    @page = opts.page
    @model.on "change:section_type", @render

  onRender: =>
    # apply localised placeholders
    @setPlaceholders()
    # bind
    @makeEditable()
    super
    # wrap editing controls around content elements
    @addEditors()

  sectionId: (id) -> 
    "section_#{id}"

  setPlaceholders: =>
    if slug = @model.get('section_type_slug')
      for att in ['title', 'primary', 'secondary', 'caption']
        ph = null
        if _cms.translationAvailable("placeholders.sections.#{slug}.#{att}")
          ph = t("placeholders.sections.#{slug}.#{att}")
        else if _cms.translationAvailable("placeholders.sections.#{att}")
          ph = t("placeholders.sections.#{att}")
        @log "setPlaceholders", slug, att, "->", ph
        if ph
          @$el.find('[data-cms-role="' + att + '"]').attr('data-placeholder', ph)

  makeEditable: =>
    @ui.editable.attr('contenteditable', 'true').addClass('editing')

  ## Edit helpers
  # Wrap html and image editors around our bound elements to provide extra editing controls.
  #
  addEditors: =>
    @ui.editable_string.each (i, el) =>
      @addView new Cms.Views.StringEditor
        model: @model
        el: el

    @ui.editable_html.each (i, el) =>
      @addView new Cms.Views.HtmlEditor
        model: @model
        el: el

    @ui.editable_background_image.each (i, el) =>
      @addView new Cms.Views.BackgroundImageEditor
        model: @model
        el: el

  # then onSet we remove all control elements and editable attribuets: 
  # the database holds exactly the html that we will display.
  #
  withoutControls: (html) =>
    @_cleaner ?= $('<div />')
    @_cleaner.html(html)
    @_cleaner.find('[data-cms]').remove()
    @_cleaner.find('[contenteditable]').removeAttr('contenteditable')
    @_cleaner.find('[data-placeholder]').removeAttr('data-placeholder')
    @_cleaner.html()

  withoutHTML: (html) =>
    @_cleaner ?= $('<div />')
    @_cleaner.html(html)
    @_cleaner.text().trim()


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


