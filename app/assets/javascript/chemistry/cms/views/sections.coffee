class Cms.Views.Section extends Cms.View
  tagName: "section"

  className: =>
    @model?.get('section_type_slug')

  bindings:
    ":el":
      class:
        deleted: "deleted_at"
      attributes: [
        name: "id"
        observe: "id"
        onGet: "sectionId"
      ]
    ## can we bind everything here or do the section_type templates vary more than that?




  initialize: =>
    super
    @log "init"
    @model.on "change:section_type", @render
    window.sv = @

  template: =>
    @log "template", @model.getTemplate()
    @model.getTemplate()

  sectionId: (id) -> 
    "section_#{id}"


class Cms.Views.NoSection extends Cms.View
  template: "no_section"


class Cms.Views.Sections extends Cms.Views.AttachedCollectionView
  childView: Cms.Views.Section
  emptyView: Cms.Views.NoSection
  # nb AttachedCollectionView is self-loading and self-rendering