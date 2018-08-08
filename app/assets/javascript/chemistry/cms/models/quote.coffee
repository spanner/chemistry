class Cms.Models.Quote extends Cms.Model
  savedAttributes: []
  defaults:
    asset_type: "quote"
    utterance: ""
    caption: ""


class Cms.Collections.Quotes extends Cms.Collection
  model: Cms.Models.Quote
