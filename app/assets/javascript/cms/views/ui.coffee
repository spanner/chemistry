## UI Construction
#
# We have only three types of view:
#
# Dashboard is a miscellaneous introduction
# Collection views display lists of editable items
# Model views display items for editing
#
# Collection views receive query string parameters to support searching, pagination and sorting.
#
class Cms.Views.UI extends Cms.View  
  template: "cms/ui"

  regions:
    nav: "#nav"
    notices: "#notices"
    main: "#main"

  onRender: =>
    @_view = null
    @_collection = null
    @getRegion('nav').show new Cms.Views.Nav
    @getRegion('notices').show new Cms.Views.Notices
      collection: _cms.notices

  defaultView: =>
    # we might want to redirect this instead.
    @collectionView 'pages'

  collectionView: (base, params) =>
    @log "collectionView", base, params
    collection_name = base.charAt(0).toUpperCase() + base.slice(1)
    collection_class = Cms.Collections[collection_name]
    view_class = Cms.Views["#{collection_name}Index"] or Cms.Views[collection_name]
    collection_params = @collectionParams(params)
    if view_class and collection_class
      if @_collection and @_collection instanceof collection_class
        @_collection.setParams collection_params
      else
        @_collection = new collection_class null,
          params: collection_params
      @showView new view_class
        collection: @_collection

  modelView: (base, action, id) =>
    @log "collectionView", base, action
    model_name = base.charAt(0).toUpperCase() + base.slice(1)
    action_name = action.charAt(0).toUpperCase() + action.slice(1)
    model_class = Cms.Models[model_name]
    view_class = Cms.Views[action_name + model_name] or Cms.Views[model_name]
    # stored collection is used to avoid fetch work if we can:
    # useful economy when navigating from list to item.
    collection_name = _.str.pluralize(model_name)
    collection_class = Cms.Collections[collection_name]
    if view_class and model_class
      if id is 'new'
        model = new model_class()
      else if @_collection and @_collection instanceof collection_class
        model = @_collection.get(id)
      model ||= new model_class({id: id})
      model.fetchIfBare()
      @showView new view_class
        model: model

  collectionParams: (params={}) =>
    _.pick params, ['p', 'pp', 'q', 's', 'o']

  showView: (view=@_view) =>
    @getRegion('main').show view

  