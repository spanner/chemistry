class Cms.Views.Nav extends Cms.View
  template: "nav"

  regions:
    controls: "#cms-controls"
    shortcuts: "#shortcuts"
    queue: "#queue"
    dialog:
      el: "#dialog"
      regionClass: Cms.FloatingRegion

  ui:
    head: "a.menu"
    nav: "nav.submenu"
    link: "a.collection"
    bg: "#navbg"
    shortcuts: "#shortcuts"
    version: "#chemistry_version"

  events:
    "click @ui.link": "hideAndGoto"

  triggers:
    "click @ui.head": "toggle"
    "click @ui.bg": "hide"

  initialize: =>
    super
    window.onbeforeunload = _cms.checkDeparture(@model)

  onRender: =>
    @getRegion('queue').show new Cms.Views.JobQueue
    @setModel(@model)
    @ui.version.text "Chemistry #{Cms.version} (#{Cms.subtitle})"

  setModel: (model) =>
    @model = model
    if model
      @getRegion('controls').show new Cms.Views.Saver(model: model)
      if model.isA('Page')
        @getRegion('shortcuts').show new Cms.Views.Shortcuts(model: model)
      @stickit()
    else
      @unsetModel()

  unsetModel: =>
    @getRegion('controls').reset()
    @getRegion('shortcuts').reset()
    @unstickit()

  hideAndGoto: (e) =>
    @trigger 'hide'
    # allow navigation event to continue
