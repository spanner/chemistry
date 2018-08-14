class Cms.Views.Saver extends Cms.View
  template: 'helpers/saver'

  ui:
    save_button: "a.save"
    revert_button: "a.revert"
    publish_button: "a.publish"
    review_button: "a.review"
    config_button: "a.config"

  events:
    "click @ui.save_button": "save"
    "click @ui.revert_button": "revertWithConfirmation"
    "click @ui.publish_button": "publishWithConfirmation"
    "click @ui.config_button": "floatConfig"

  bindings:
    "a.save":
      classes:
        unavailable:
          observe: ["changed", "valid"]
          onGet: "unSaveable"
    "a.revert":
      classes: 
        unavailable:
          observe: "changed"
          onGet: "unRevertable"
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
          observe: "published_at"
          onGet: "unReviewable"

  onRender: =>
    super
    @ui.publish_button.hide() unless @model.is_a('Page')

  floatConfig: (e) =>
    e?.preventDefault()
    config_page_view = new Cms.Views.ConfigPage
      model: @model
    _cms.ui.floatView config_page_view


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
      top: position.top
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


class Cms.Views.ReversionConfirmation extends Cms.Views.Confirmation
  template: "helpers/reversion_confirmation"


class Cms.Views.PublicationConfirmation extends Cms.Views.Confirmation
  template: "helpers/publication_confirmation"


class Cms.Views.DeletionConfirmation extends Cms.Views.Confirmation
  template: "helpers/deletion_confirmation"

  enact: () =>
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
