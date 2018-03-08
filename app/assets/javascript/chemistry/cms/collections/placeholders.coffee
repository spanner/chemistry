class Cms.Collections.Placeholders extends Cms.Collection
  model: Cms.Models.Placeholder
  comparator: "position"
  paginated: false
  sorted: false

  initialize: (array, opts) ->
    @template = opts.template
