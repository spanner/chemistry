class Cms.Views.Image extends Cms.Views.ItemView
  tagName: "image"

  bindings:
    ":el":
      class:
        deleted: "deleted_at"

# image preview
# listed image
# attached image


class Cms.Views.NoImage extends Cms.Views.ItemView
  template: "cms/no_image"


class CMS.Views.Images extends Cms.CollectionView
  childView: Cms.Views.Image
  emptyView: Cms.Views.NoImage
