class Cms.Models.Section extends Cms.Model
  savedAttributes: ["id", "page_id", "title", "main", "aside", "section_type", "subject_page_id", "position", "image_id", "video_id", "deleted_at"]

  build: =>
    @belongsTo 'section_type', _cms.section_types

  getTemplate: =>
    if section_type = @get('section_type')
      section_type.get("template")
    else
      '<p class="warning">Section has no type</p>'