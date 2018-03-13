class Cms.Models.Section extends Cms.Model
  savedAttributes: ["id", "page_id", "title", "primary_html", "secondary_html", "section_type", "subject_page_id", "position", "image_id", "video_id", "deleted_at"]

  build: =>
    @belongsTo 'section_type', _cms.section_types
    @on "change:section_type", @setSlug
    # @setSlug()

  getTemplate: =>
    if section_type = @get('section_type')
      section_type.get("template")
    else
      '<p class="warning">Section has no type</p>'

  setSlug: (section_type) =>
    @set 'section_type_slug', section_type?.get('slug')