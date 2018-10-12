# Sections are saved as a nested resource within the page object
# so that we can offer a nice simple save and publish workflow.
#
class Cms.Models.Social extends Cms.Model
  savedAttributes: ["id", "serial_id", "platform", "name", "url"]

  defaults:
    platform: "web"


class Cms.Collections.Socials extends Cms.Collection
  model: Cms.Models.Social
  comparator: "position"
  paginated: false
