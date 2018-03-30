class Cms.Models.Job extends Backbone.Model
  defaults:
    status: "active"
    progress: 0
    completed: false

  initialize: () ->
    @on "change:progress", @completeIfCompleted

  setProgress: (p) =>
    if p.lengthComputable
      perc = Math.round(10000 * p.loaded / p.total) / 100.0
      @set("progress", perc)

  setStatus: (value) =>
    @set("status", value)

  finish: () =>
    @set("progress", 100)
    @set('completed', true)

  discard: () =>
    @collection?.remove(this) or this.destroy()

  fail: (error) =>
    @set "failed", true
    @set "error", error


class Cms.Collections.Jobs extends Backbone.Collection
  model: Cms.Models.Job
