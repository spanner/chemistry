class Cms.Models.Quote extends Cms.Model
  savedAttributes: []
  defaults:
    utterance: ""
    caption: ""


class Cms.Collections.Images extends Cms.Collection
  model: Cms.Models.Quote
