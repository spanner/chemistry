class Cms.Views.Saver extends Cms.View
  template: 'helpers/saver'

  ui:
    save_button: "a.save"
    revert_button: "a.revert"
    publish_button: "a.publish"

  events:
    "click @ui.save_button": "save"
    "click @ui.revert_button": "revert"
    "click @ui.publish_button": "publish"

  bindings:
    "a.save":
      classes: 
        available:
          observe: ["changed", "valid"]
          onGet: "ifSaveable"
    "a.revert":
      classes: 
        available:
          observe: "changed"
          onGet: "ifRevertable"
    "a.publish":
      classes: 
        available:
          observe: ["changed", "valid", "unpublished"]
          onGet: "ifPublishable"

  onRender: =>
    super
    @ui.publish_button.hide() unless @model.is_a('Page')

  save: =>
    @model.save()

  revert: =>
    @model.revert()

  publish: =>
    @model.publish()

  # Object is saveable if it valid and has significant changes.
  #
  ifSaveable: ([changed, valid]=[]) =>
    changed and valid

  # Object is revertable if it has significant changes.
  #
  ifRevertable: (changed) =>
    @log "ifRevertable", changed
    !!changed

  # page is publishable if it has no unsaved changes,
  # and the current publication is out of date.
  #
  ifPublishable: ([changed, valid, unpublished]=[]) =>
    valid and unpublished and not changed


class Cms.Views.Confirmation extends Cms.View
  className: "confirm"
  template: "helpers/confirmation"

  ui:
    message: "span.message"

  events: 
    "click a.confirm": "confirm"
    "click a.cancel": "cancel"
  
  initialize: (options) ->
    @link = $(options.link)
    @log "Confirmation", options
    @log "link", @link
    @message = @link.data('confirmation')
    @final_confirmation = @link.data('final-confirmation')
    @action = options.action
    @and_then = options.and_then
    @render()

  onRender: () =>
    @log "render", @el, @link
    position = @link.offset()
    @$el.appendTo(_cms.el)
    @$el.css
      left: position.left + @link.width()
      top: position.top - @$el.height()
    @ui.message.text(@message) if @message
    @stickit()
    @$el.fadeIn('fast')

  cancel: (e) =>
    e.preventDefault() if e
    @$el.fadeOut () =>
      @remove()

  confirm: (e) =>
    e.preventDefault() if e
    if !@final_confirmation or window.confirm(@final_confirmation)
      @enact()
    else
      @cancel()

  enact: () =>
    @log "Enact"
    @action.call()
    @remove()
    @and_then?()


class Cms.Views.DeletionConfirmation extends Cms.Views.Confirmation
  template: "helpers/deletion_confirmation"

  enact: () =>
    @log "Enact deletion", @and_then
    @model.destroy()
    @remove()
    @and_then?()


class Cms.Views.Deleter extends Cms.View
  template: false
  tagName: "a"

  events:
    "click": "deleteWithConfirmation"

  deleteWithConfirmation: (e) =>
    e?.preventDefault()
    new Cms.Views.DeletionConfirmation
      model: @model
      link: @$el
      confirm: @$el.data('confirmation')


