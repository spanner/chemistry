class Cms.Views.Nav extends Cms.View
  template: "nav"

  regions:
    controls: "#cms-controls"
    queue: "#queue"
    dialog:
      el: "#dialog"
      regionClass: Cms.FloatingRegion

  ui:
    head: "a.menu"
    nav: "nav.submenu"
    bg: "#navbg"

  triggers:
    "click @ui.head": "toggle"
    "click @ui.nav": "hide"
    "click @ui.bg": "hide"

  onRender: =>
    @getRegion('queue').show new Cms.Views.JobQueue
    @setModel(@model)

  setModel: (model) =>
    if model
      @getRegion('controls').show new Cms.Views.Saver(model: model)
    else
      @getRegion('controls').reset()
