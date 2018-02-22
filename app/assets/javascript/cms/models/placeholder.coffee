class Cms.Models.Section extends Cms.Model
  savedAttributes: ["id", "page_id", "title", "main", "aside", "section_type", "subject_page_id", "position", "image_id", "video_id", "deleted_at"]

  getTemplate: =>
    @collection?.template
