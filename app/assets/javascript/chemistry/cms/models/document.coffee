class Cms.Models.Document extends Cms.Model
  savedAttributes: ["title", "caption", "file_data", "file_name", "remote_url"]
  uploadProgress: true


class Cms.Collections.Documents extends Cms.Collection
  model: Cms.Models.Document
