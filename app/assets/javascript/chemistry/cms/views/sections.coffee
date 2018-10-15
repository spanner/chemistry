# Bindings and editables are separate concerns here.
# We bind based on `cms-role` declarations and edit based on `cms-editor` declarations.
#
# This makes ad-hoc variation more easy but it's hard to express rules like 'secondary html should have no asset inserter and only a formatting toolbar'
#
class Cms.Views.Section extends Cms.View
  tagName: "section"
  className: => @model?.get('section_type_slug')
  template: => @model?.getTemplate()

  @shorterThan: (limit) ->
    (value) -> 
      value?.length and value.length < limit

  @longerThan: (limit) ->
    (value) ->
      value?.length and value.length > limit

  ui:
    editable: '[data-cms-editor]'
    editable_background: '[data-cms-editor="bg"]'
    editable_html: '[data-cms-editor="html"]'
    editable_string: '[data-cms-editor="string"]'
    contents_list: '[data-cms-role="contents"]'
    socials_list: '[data-cms-role="socials"]'

  events:
    "click a.popup": "popMeUp"

  bindings:
    ":el":
      class:
        deleted: "deleted_at"
      attributes: [
        name: "id"
        observe: "id"
        onGet: "sectionId"
      ]
    '[data-cms-role="prefix"]':
      observe: "prefix"
      onSet: "withoutHTML"
    '[data-cms-role="title"]':
      observe: "title"
      onSet: "withoutHTML"
      classes:
        short:
          observe: "title"
          onGet: @shorterThan(14)
        quiteshort:
          observe: "title"
          onGet: @shorterThan(24)
        quitelong:
          observe: "title"
          onGet: @longerThan(34)
        long:
          observe: "title"
          onGet: @longerThan(44)
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
    # add contenteditable property where needed
    @makeEditable()
    # add data-placeholder attributes to contenteditables
    @setPlaceholders()
    # base onRender adds extra bindings and calls stickit
    @stickit()
    @log "after sticking it", @$el.find('[data-cms-role="title"]').text()
    # wrap editors around embedded assets
    @addEditors()
    # mock up a contents list if holder found on section template
    @showContents()
    # show socials-list editor if holder found on section template
    @showSocials()

  sectionId: (id) ->
    @log "sectionId", id
    "section_#{id}"

  setPlaceholders: =>
    if slug = @model.get('section_type_slug')
      for att in ['prefix', 'title', 'primary', 'secondary', 'caption']
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
      @log "background", el
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

  showSocials: =>
    if @ui.socials_list.length
      for platform in ['twitter', 'facebook', 'instagram']
        listView = new Cms.Views.SocialsManager
          collection: @page.socials
          platform: platform
        @ui.socials_list.append listView.el
        listView.render()


  #TODO: This is way out of place and needs to be made general or binned, but it is convenient here.
  # called on click a.popup
  #
  popMeUp: (e) =>
    e?.preventDefault()
    if target = e?.target
      $link = $(target)
      $popup = $link.siblings('.popup')
      $popup.addClass('up')
      $link.addClass('up')
      $popup.find('a.close').click =>
        $popup.removeClass('up')
        $link.removeClass('up')


class Cms.Views.SectionEditor extends Cms.Views.Section
  template: "sections/editor"


#todo: strip out data-cms attributes
#
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
    '[data-cms-role="prefix"]':
      observe: "prefix"
      updateMethod: "html"
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
    if @ui.socials_list.length
      listView = new Cms.Views.SocialsList
        collection: @page.socials
      @ui.socials_list.append listView.el
      listView.render()


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

