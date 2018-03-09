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
  template: "ui"

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

  reset: =>
    Backbone.history.loadUrl(Backbone.history.fragment)

  defaultView: =>
    # we might want to redirect this instead.
    @collectionView 'pages'

  collectionView: (base, params) =>
    @log "collectionView", base, params
    if ['pages', 'templates', 'section_types', 'images', 'videos', 'documents'].indexOf(base) is -1
      _cms.complain "Unknown object type: #{base}"
    else
      @_collection = _cms[base]
      @_collection.setParams collection_params
      view_class_name = base.charAt(0).toUpperCase() + base.slice(1)
      view_class = Cms.Views["#{view_class_name}Index"] or Cms.Views[view_class_name]
      collection_params = @collectionParams(params)
      if @_collection and view_class
        @_collection.setParams collection_params
        # always rebuild?
        @showView new view_class
          collection: @_collection

  modelView: (base, action, id) =>
    @log "modelView", base, action
    if ['page', 'template', 'section_type', 'image', 'video', 'document'].indexOf(base) is -1
      _cms.complain "Unknown object type: #{base}"
    else
      model_name = base.charAt(0).toUpperCase() + base.slice(1)
      action_name = action.charAt(0).toUpperCase() + action.slice(1)
      model_class = Cms.Models[model_name]
      view_class = Cms.Views[action_name + model_name] or Cms.Views[model_name]
      if view_class and model_class
        collection_name = model_name + 's'    # take that, ActiveSupport
        collection_class = Cms.Collections[collection_name]
        if id is 'new'
          model = new model_class()
        else if @_collection and @_collection instanceof collection_class
          model = @_collection.get(id)
        model ||= new model_class({id: id})
        model.loadIfBare()
        @showView new view_class
          model: model

  collectionParams: (params={}) =>
    _.pick params, ['p', 'pp', 'q', 's', 'o']

  showView: (view=@_view) =>
    @getRegion('main').show view

  