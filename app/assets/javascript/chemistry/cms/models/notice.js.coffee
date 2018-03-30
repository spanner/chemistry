class Cms.Models.Notice extends Backbone.Model

  initialize: =>
    @set "created_at", new Date

  discard: =>
    @collection.remove(@)


class Cms.Collections.Notices extends Backbone.Collection
  model: Cms.Models.Notice
  comparator: "created_at"