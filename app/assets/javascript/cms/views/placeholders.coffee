class Cms.Views.Placeholder extends Cms.Views.ItemView
  tagName: "section"
  className: "placeholder"


class Cms.Views.NoPlaceholder extends Cms.Views.ItemView
  template: "cms/no_placeholder"


class CMS.Views.Placeholders extends Cms.CollectionView
  childView: Cms.Views.Placeholder
  emptyView: Cms.Views.NoPlaceholder
