class Cms.Models.Video extends Cms.Model
  savedAttributes: ["title", "caption", "file", "file_name", "remote_url"]

class Cms.Collections.Videos extends Cms.Collection
  model: Cms.Models.Video
