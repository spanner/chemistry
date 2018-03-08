class Cms.Views.Placeholder extends Cms.View
  tagName: "section"
  className: "placeholder"


class Cms.Views.NoPlaceholder extends Cms.View
  template: "no_placeholder"


class Cms.Views.Placeholders extends Cms.CollectionView
  childView: Cms.Views.Placeholder
  emptyView: Cms.Views.NoPlaceholder
