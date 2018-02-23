class Cms.Views.Section extends Cms.Views.ItemView
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


class Cms.Views.NoSection extends Cms.Views.ItemView
  template: "cms/no_section"


class CMS.Views.Sections extends Cms.CollectionView
  childView: Cms.Views.Section
  emptyView: Cms.Views.NoSection
