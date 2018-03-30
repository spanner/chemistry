# Sections are saved as a nested resource within the page object
# so that we can offer a nice simple save and publish workflow.
#
class Cms.Models.Section extends Cms.Model
  savedAttributes: ["id", "page_id", "title", "primary_html", "secondary_html", "section_type", "subject_page_id", "position", "image_id", "video_id", "deleted_at"]

  defaults:
    title: ""
    primary_html: ""
    secondary_html: ""

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


class Cms.Collections.Sections extends Cms.Collection
  model: Cms.Models.Section
  comparator: "position"
  paginated: false
  sorted: false

  setDefaults: =>
    if @_nested
      if first_section = @first()
        slug = first_section.get('section_type_slug')
        if slug is 'hero' or slug is 'title'
          first_section.setDefault 'title', @_nested?.get('title')
  