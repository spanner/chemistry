class Cms.Models.LinkButton extends Cms.Model
  savedAttributes: []
  defaults:
    asset_type: "linkbutton"
    url: ""
    label: ""
    symbol: ""
    caption: ""


class Cms.Collections.LinkButtons extends Cms.Collection
  model: Cms.Models.LinkButton
