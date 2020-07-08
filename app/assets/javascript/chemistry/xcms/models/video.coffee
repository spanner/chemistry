class Cms.Models.Video extends Cms.Model
  savedAttributes: ["title", "caption", "file_data", "file_name", "file_type", "remote_url"]
  uploadProgress: true
  defaults:
    asset_type: "video"


  # TODO: grab frame thumbnail

class Cms.Collections.Videos extends Cms.Collection
  model: Cms.Models.Video
