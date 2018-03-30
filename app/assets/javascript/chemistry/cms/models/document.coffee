class Cms.Models.Document extends Cms.Model
  savedAttributes: ["title", "caption", "file", "file_name", "remote_url"]


class Cms.Collections.Documents extends Cms.Collection
  model: Cms.Models.Document
