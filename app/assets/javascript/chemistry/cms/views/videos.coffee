class Cms.Views.ListedVideo extends Cms.View

  bindings:
    ":el":
      class:
        deleted: "deleted_at"

# video preview
# listed video
# attached video


class Cms.Views.NoListedVideo extends Cms.View
  template: "no_video"


class Cms.Views.Videos extends Cms.CollectionView
  childView: Cms.Views.ListedVideo
  emptyView: Cms.Views.NoListedVideo

