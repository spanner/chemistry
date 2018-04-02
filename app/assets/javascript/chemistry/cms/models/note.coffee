class Cms.Models.Note extends Cms.Model
  savedAttributes: []
  defaults:
    text: ""


class Cms.Collections.Notes extends Cms.Collection
  model: Cms.Models.Note
