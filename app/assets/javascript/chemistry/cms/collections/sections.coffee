# Sections are saved as a nested resource within the page object
# so that we can offer a nice simple save and publish workflow.
# Once we start reusing sections then something more clever will
# be required.
#
class Cms.Collections.Sections extends Cms.Collection
  model: Cms.Models.Section
  comparator: "position"
  paginated: false
  sorted: false
