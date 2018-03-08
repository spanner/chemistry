class Cms.Views.Notice extends Cms.View
  template: "notice"
  tagName: "li"

  events:
    "click": "fadeOut"

  bindings:
    ".message":
      observe: "message"
      updateMethod: "html"
    ":el":
      attributes: [
        name: "class"
        observe: "notice_type"
      ]

  onRender: =>
    @stickit()
    _.delay @fadeOut, @model.get('duration') ? 4000

  fadeOut: (duration=500) =>
    @$el.fadeOut duration, @close

  close: (e) =>
    @$el.stop(true, false).hide()
    @model.discard()

  ifError: (value) =>
    value is 'error'

  ifConfirmation: (value) =>
    value is 'confirmation'


class Cms.Views.Notices extends Cms.CollectionView
  childView: Cms.Views.Notice
  tagName: "ul"
  className: "notices"
