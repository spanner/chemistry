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
      @getRegion('controls').show new Cms.Views.Saver(model: model)
    else
      @getRegion('controls').reset()

  toggleNav: =>
    if @ui.nav.hasClass('up')
      @hideNav()
    else
      @showNav()

  hideNav: =>
    @ui.nav.removeClass('up')

  showNav: =>
    @ui.nav.addClass('up')

