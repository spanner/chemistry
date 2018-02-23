class Cms.Views.Video extends Cms.View

  bindings:
    ":el":
      class:
        deleted: "deleted_at"

# video preview
# listed video
# attached video


class Cms.Views.NoVideo extends Cms.View
  template: "cms/no_video"


class Cms.Views.Videos extends Cms.CollectionView
  childView: Cms.Views.Video
  emptyView: Cms.Views.NoVideo
