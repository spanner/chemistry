class Cms.Views.Document extends Cms.View
  tagName: "document"

  bindings:
    ":el":
      class:
        deleted: "deleted_at"

# document preview
# listed document
# attached document


class Cms.Views.NoDocument extends Cms.View
  template: "no_document"


class Cms.Views.Documents extends Cms.CollectionView
  childView: Cms.Views.Document
  emptyView: Cms.Views.NoDocument
