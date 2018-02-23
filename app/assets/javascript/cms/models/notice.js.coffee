class Cms.Models.Notice extends Backbone.Model

  initialize: =>
    @set "created_at", new Date

  discard: =>
    @collection.remove(@)
