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
class Cms.Views.Ui extends Amp.View  
  template: "amp/ui"

  regions:
    nav: "#nav"
    notices: "#notices"
    main: "#main"

  onRender: =>
    @_showing_view = null
    @_showing_model = null
    @_nav ?= new Cms.Views.Navigation
      el: @ui.nav
    @getRegion('nav').show(@_nav)
    @_notices ?= new Cms.Views.Notices
      collection: _cms.notices
      el: @ui.notices
    @getRegion('notices').show(@_notices)

  dashboardView: =>
    view_class = Cms.Views.Dashboard
    if @_showing_view? and @_showing_view instanceof view_class
      @_showing_view.render()
    else
      @showView new view_class

  contentView: (base, id, params) =>
    if id
      @modelView base, id, params
    else
      @collectionView base, params

  modelView: (base, id, params) =>
    model_name = base.charAt(0).toUpperCase() + base.slice(1)
    model_class = Cms.Models[model_name]
    view_class = Cms.Views[model_name]
    if view_class and collection_class
      if id is 'new'
        model = new model_class()
      else
        model = new model_class({id: id})                                              #todo retrieve a previously fetched model
      if @_showing_view? and @_showing_view instanceof view_class
        @_showing_view.setModel model
      else
        @showView new view_class
          model: model

  collectionView: (base, params) =>
    collection_name = _.str.pluralize(base.charAt(0).toUpperCase() + base.slice(1))
    collection_class = Cms.Collections[collection_name]
    view_class = Cms.Views[collection_name]
    collection_params = @collectionParams(params)
    if view_class and collection_class
      if @_showing_view? and @_showing_view instanceof view_class
        @_showing_view.setParams collection_params
      else
        collection = new collection_class null,
          params: collection_params
        @showView new view_class
          collection: collection

  collectionParams: (params={}) =>
    _.pick params, ['p', 'pp', 'q', 's', 'o']

  showView: (view=@_showing_view) =>
    @getRegion('main').show view
    @_showing_view = view

  