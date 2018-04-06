class Cms.Views.Nav extends Cms.View
  template: "nav"

  regions:
    controls: "#controls"
    queue: "#queue"
    dialog:
      el: "#dialog"
      regionClass: Cms.FloatingRegion

  ui:
    head: "a.menu"
    nav: "nav.submenu"

  events:
    "click @ui.head": "toggleNav"
    "click @ui.nav": "hideNav"

  onRender: =>
    @getRegion('queue').show new Cms.Views.JobQueue
    @setModel(@model)

  setModel: (model) =>
    if model
      saver = new Cms.Views.Saver(model: model)
      saver.on 'config', @showConfig
      @getRegion('controls').show saver
    else
      @getRegion('controls').reset()

  showConfig: =>
    # make more decisions when it becomes possible that model is not a page
    config_page_view = new Cms.Views.ConfigPage
      model: @model
    @getRegion('dialog').show config_page_view
    config_page_view.on "cancel close", @hideDialog

  hideConfig: =>
    @getRegion('dialog').reset()

  toggleNav: =>
    if @ui.nav.hasClass('up')
      @hideNav()
    else
      @showNav()

  hideNav: =>
    @ui.nav.removeClass('up')

  showNav: =>
    @ui.nav.addClass('up')

