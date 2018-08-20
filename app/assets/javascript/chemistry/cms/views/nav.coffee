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
    shortcuts: ".shortcuts"
    save_button: "a.save.shortcut"
    publish_button: "a.publish.shortcut"
    review_button: "a.review.shortcut"

  events:
    "click @ui.save_button": "save"
    "click @ui.publish_button": "publishWithConfirmation"
    "click @ui.link": "hideAndGoto"

  triggers:
    "click @ui.head": "toggle"
    "click @ui.bg": "hide"

  bindings:
    "a.save":
      classes:
        unavailable:
          observe: ["changed", "valid", "unpublished"]
          onGet: "unSaveable"
    "a.publish":
      classes: 
        unavailable:
          observe: ["changed", "valid", "unpublished"]
          onGet: "unPublishable"
    "a.review":
      attributes: [
        name: "href"
        observe: "path"
        onGet: "absolutePath"
      ]
      classes: 
        unavailable:
          observe: ["changed", "valid", "unpublished"]
          onGet: "unReviewable"

  initialize: =>
    super
    window.onbeforeunload = _cms.checkDeparture(@model)

  onRender: =>
    @getRegion('queue').show new Cms.Views.JobQueue
    @setModel(@model)

  setModel: (model) =>
    @model = model
    if model
      @getRegion('controls').show new Cms.Views.Saver(model: model)
      @ui.shortcuts.show()
      @stickit()
    else
      @unsetModel()

  unsetModel: =>
    @getRegion('controls').reset()
    @ui.shortcuts.hide()
    @unstickit()

  hideAndGoto: (e) =>
    @trigger 'hide'
    # allow navigation event to continue

  # The actions overlay has a preview button whenever it's possible to preview,
  # but here we only show the shortcut when neither save nor publish is appropriate
  # (and if we have ever been published). Usual double negative :|
  #
  unReviewable: ([changed, valid, unpublished]=[]) =>
    unpublished or !@unSaveable([changed, valid, unpublished]) or !@unPublishable([changed, valid, unpublished])

  hideShortcuts: =>
    @ui.save_button.addClass('unavailable')
    @ui.publish_button.addClass('unavailable')
    @ui.review_button.addClass('unavailable')


