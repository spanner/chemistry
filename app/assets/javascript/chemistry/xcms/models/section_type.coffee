class Cms.Models.SectionType extends Cms.Model
  defaults:
    template: '<p class="warning">Section type<span class="section_type_name"></span>: No template available</p>'


class Cms.Collections.SectionTypes extends Cms.Collection
  model: Cms.Models.SectionType
  paginated: false
