# The sorter holds a representation of collection sort state.
# At the moment that means it will be either 'name' or 'date', and 'asc' or 'desc'.
# That can have different meaning in each collection, but usually it means exactly what you'd expect.

class Cms.Models.Sorter extends Backbone.Model
  defaults:
    sort_by: "date"
    sort_order: "desc"

  # if sort_type is the current value, reverse the sort_order.
  # If it is a new value, set sort_by and default sort_order.
  #
  setSort: (attribute) =>
    if @get('sort_by') is attribute
      @set
        sort_order: @reverseOrder()
    else
      @set
        sort_by: attribute
        sort_order: if attribute is 'date' then 'desc' else 'asc'

  reverseOrder: =>
    if @get('sort_order') is 'asc' then 'desc' else 'asc'

  defaultOrderFor: (sort_by) =>
    if sort_by is 'date' then 'desc' else 'asc'