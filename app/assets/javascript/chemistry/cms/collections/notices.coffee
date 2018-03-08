class Cms.Collections.Notices extends Backbone.Collection
  model: Cms.Models.Notice
  comparator: "created_at"