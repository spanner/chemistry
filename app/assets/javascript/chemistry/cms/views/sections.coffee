class Cms.Views.Section extends Cms.View
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

  initialize: =>
    super
    @model.on "change:section_type", @render

  template: =>
    @model.getTemplate()

  sectionId: (id) -> 
    "section_#{id}"


class Cms.Views.NoSection extends Cms.View
  template: "no_section"


class Cms.Views.Sections extends Cms.CollectionView
  childView: Cms.Views.Section
  emptyView: Cms.Views.NoSection
