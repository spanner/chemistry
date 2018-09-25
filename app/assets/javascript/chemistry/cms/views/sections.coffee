# Bindings and editables are separate concerns here.
# We bind based on `cms-role` declarations and edit based on `cms-editor` declarations.
#
# This makes ad-hoc variation more easy but it's hard to express rules like 'secondary html should have no asset inserter and only a formatting toolbar'
#
class Cms.Views.Section extends Cms.View
  tagName: "section"
  className: => @model?.get('section_type_slug')
  template: => @model?.getTemplate()

  ui:
    editable: '[data-cms-editor]'
    editable_background: '[data-cms-editor="bg"]'
    editable_html: '[data-cms-editor="html"]'
    editable_string: '[data-cms-editor="string"]'
    contents_list: '[data-cms-role="contents"]'

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
    @makeEditable()
    @setPlaceholders()
    super
    @addEditors()
    @showContents()

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
        if ph
          @$el.find('[data-cms-role="' + att + '"]').attr('data-placeholder', ph)

  makeEditable: =>
    @bindUIElements()
    @ui.editable_string.attr('contenteditable', 'plaintext-only')
    @ui.editable_html.attr('contenteditable', true)
    @ui.editable.addClass('editing')

  ## Edit helpers
  # Wrap html and image editors around our bound elements to provide extra editing controls.
  #
  addEditors: =>
    @ui.editable_string.each (i, el) =>
      @addView new Cms.Views.EditableString
        model: @model
        el: el

    @ui.editable_html.each (i, el) =>
      @addView new Cms.Views.EditableHtml
        model: @model
        el: el

    # Background is not the usual contenteditable situation, but an asset view attached directly to the section.
    # We don't bind it, but instead let the EditableBackground manage the background_html attribute directly.
    @ui.editable_background.each (i, el) =>
      $(el).html @model.get('background_html')
      @addView new Cms.Views.EditableBackground
        model: @model
        el: el

  showContents: =>
    @ui.contents_list.each (i, el) =>
      $(el).attr('data-page', @page.get('path'))
      @addView new Cms.Views.ChildPages
        collection: @page.getChildren()
        el: el


class Cms.Views.SectionRenderer extends Cms.Views.Section
  tagName: "section"

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
    '[data-cms-role="background"]':
      observe: "background_html"
      updateMethod: "html"

  onRender: =>
    @stickit()
    @ui.contents_list.attr('data-page', @page.get('path'))


class Cms.Views.NoSection extends Cms.View
  template: "no_section"


class Cms.Views.Sections extends Cms.CollectionView
  childView: Cms.Views.Section
  emptyView: Cms.Views.NoSection
  # nb AttachedCollectionView is self-loading and self-rendering

  childViewOptions: (model) =>
    page: @page

  initialize: (opts={}) =>
    @page = opts.page
    super


class Cms.Views.RenderedSections extends Cms.Views.Sections
  childView: Cms.Views.SectionRenderer

