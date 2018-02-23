class Cms.Views.Video extends Cms.Views.ItemView
  tagName: "video"

  bindings:
    ":el":
      class:
        deleted: "deleted_at"

# video preview
# listed video
# attached video


class Cms.Views.NoVideo extends Cms.Views.ItemView
  template: "cms/no_video"


class CMS.Views.Videos extends Cms.CollectionView
  childView: Cms.Views.Video
  emptyView: Cms.Views.NoVideo
