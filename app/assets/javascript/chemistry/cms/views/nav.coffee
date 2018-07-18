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
    link: "a.collection"
    bg: "#navbg"
    save_button: "a.save_shortcut"
    publish_button: "a.publish_shortcut"

  events:
    "click @ui.save_button": "save"
    "click @ui.publish_button": "publishWithConfirmation"
    "click @ui.link": "hideAndGoto"

  triggers:
    "click @ui.head": "toggle"
    "click @ui.bg": "hide"

  bindings:
    "a.save_shortcut":
      classes:
        unavailable:
          observe: ["changed", "valid"]
          onGet: "unSaveable"
    "a.publish_shortcut":
      classes: 
        unavailable:
          observe: ["changed", "valid", "unpublished"]
          onGet: "unPublishable"

  onRender: =>
    @getRegion('queue').show new Cms.Views.JobQueue
    @setModel(@model)

  setModel: (model) =>
    @model = model
    if model
      @getRegion('controls').show new Cms.Views.Saver(model: model)
      @stickit()
    else
      @getRegion('controls').reset()
      @unstickit()

  hideAndGoto: (e) =>
    @trigger 'hide'
    # allow event to continue