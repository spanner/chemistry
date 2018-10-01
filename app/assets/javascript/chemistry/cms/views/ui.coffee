# The Router maps routes onto UI function calls and their arguments.
# It is called on every change of window.location.
#
class Cms.Router extends Backbone.Router
  routes:
    "": "defaultView"
    ":collection_name": "collectionView"
    ":collection_name(?:qs)": "collectionView"
    ":model_name/:action/:id": "modelView"

  initialize: (opts) ->
    @ui = opts.ui

  defaultView: =>
    @ui.defaultView()

  collectionView: (base, qs) =>
    @ui.collectionView(base, qs)

  modelView: (base, action, id) =>
    @ui.modelView(base, action, id)


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
    nav: "#cms-nav"
    notices: "#notices"
    main: "#main"
    floater:
      el: "#floater"
      regionClass: Cms.FloatingRegion

  ui:
    nav: "#cms-nav"

  onRender: =>
    @_view = null
    @_collection = null
    @_nav = new Cms.Views.Nav
    @_nav.on "toggle", @toggleNav
    @_nav.on "hide", @hideNav
    @showChildView 'nav', @_nav
    @showChildView 'notices', new Cms.Views.Notices
      collection: _cms.notices

  reset: =>
    Backbone.history.loadUrl(Backbone.history.fragment)

  defaultView: =>
    @collectionView 'pages'

  collectionView: (base, params) =>
    @log "collectionView", base, params
    @adminView(base, 'index', null, params)

  modelView: (base, action, id) =>
    @log "modelView", base, action
    if base is 'pages'
      @pageView(id)
    else
      @adminView(base, action, id)

  pageView: (id) =>
    @log "pageView", id
    page = _cms.pages.get(id) or new Cms.Models.Page({id: id})
    page.loadAnd =>
      @showChildView 'main', new Cms.Views.PageEditor
        model: page
      @setNavModel page

  adminView: (base, action, id, params) =>
    model_name = _cms.titlecase(_cms.singularize(base))
    @log "adminView", base, action, id, params, model_name
    if model_class = Cms.Models[model_name]
      collection_name = _cms.pluralize(model_name)
      collection_class = Cms.Collections[collection_name]
      unless @_collection and @_collection instanceof collection_class
        @_collection = _cms[collection_name.toLowerCase()] ? new collection_class

      if action is 'index'
        @log "-> index", @_collection
        @clearNavModel()
        @showChildView 'main', new Cms.Views.AdminCollectionView
          collection: @_collection
          params: params

      else if id
        model = @_collection?.get(id) ? new model_class({id: id})
        @log "-> item", model
        @clearNavModel()
        model.loadAnd =>
          @showChildView 'main', new Cms.Views.AdminItemView
            model: model
            action: action


  collectionParams: (params={}) =>
    _.pick params, ['p', 'pp', 'q', 's', 'o']


  # Nav presents the save / revert / publish controls
  # and the main collection view navigation links.
  #
  setNavModel: (model) =>
    @_nav.setModel(model)

  clearNavModel: () =>
    @_nav.unsetModel()

  toggleNav: =>
    if @ui.nav.hasClass('up')
      @hideNav()
    else
      @showNav()

  hideNav: (e) =>
    @ui.nav.removeClass('up')

  showNav: (e) =>
    @ui.nav.addClass('up')


  ## Modal overlays
  #
  # Child views call _cms.ui.floatView to put something here.
  # Floating region handles closure, masking, etc.
  #
  floatView: (view, options={}) =>
    @showChildView 'floater', view, options


## Admin layouts
#
# are here to encapsulate the admin CRUD and keep it separate from page editing,
# though at the moment their only role is to add an `article.admin` wrapper element.

class Cms.Views.AdminItemView extends Cms.View
  template: ""
  tagName: "article"
  className: "cms-admin"

  initialize: (opts={}) ->
    @log "init"
    if ['edit', 'show'].indexOf(opts.action) is -1
      _cms.complain "Unknown admin action: #{@_action}"
    else
      @action = opts.action
      super

  onRender: =>
    if @model and @action
      model_name = @model.className()
      action_name = _cms.titlecase @action
      if view_class = Cms.Views[action_name + model_name] or Cms.Views[model_name]
        view = new view_class
          model: @model
        view.$el.appendTo @$el
        view.render()


class Cms.Views.AdminCollectionView extends Cms.View
  tagName: "article"
  className: "cms-admin"

  initialize: ->
    @log "^ init", @getOption('template')
    window.wtf = @
    super

  onRender: =>
    @log "-> onRender", @collection
    if @collection
      collection_name = @collection.className()
      if view_class = Cms.Views["#{collection_name}Index"] ? Cms.Views[collection_name]
        view = new view_class
          collection: @collection
        view.$el.appendTo @$el
        view.render()
        @log "-> view in", view.$el

