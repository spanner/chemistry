class Cms.Views.Image extends Cms.View

  bindings:
    ":el":
      class:
        deleted: "deleted_at"

# image preview
# listed image
# attached image


class Cms.Views.NoImage extends Cms.View
  template: "no_image"


class Cms.Views.Images extends Cms.CollectionView
  childView: Cms.Views.Image
  emptyView: Cms.Views.NoImage
