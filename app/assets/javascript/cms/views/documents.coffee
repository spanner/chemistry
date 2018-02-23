class Cms.Views.Document extends Cms.Views.ItemView
  tagName: "document"

  bindings:
    ":el":
      class:
        deleted: "deleted_at"

# document preview
# listed document
# attached document


class Cms.Views.NoDocument extends Cms.Views.ItemView
  template: "cms/no_document"


class CMS.Views.Documents extends Cms.CollectionView
  childView: Cms.Views.Document
  emptyView: Cms.Views.NoDocument
