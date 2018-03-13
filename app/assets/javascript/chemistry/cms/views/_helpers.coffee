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



class Cms.Views.ProgressBar extends Cms.View
  template: false
  tagName: "span"
  className: "cms-progress"
  
  bindings:
    ":el":
      observe: "progressing"
      visible: true
    ".label":
      observe: "progress"
      update: "progressLabel"

  onRender: () =>
    @initProgress()
    @stickit() if @model
    @model?.on "change:progress", @showProgress

  setModel: (model) =>
    @model = model
    @render()

  initProgress: =>
    @$el.append('<div class="label"></div>')
    #TODO svg progress arc

  showProgress: (model, progress) =>
    @initProgress() unless @$el.data('circle-progress')
    if progress > 1
      @$el.fadeOut(1000)
    else
      @$el.show() unless @$el.is(':visible')
      #TODO adjust svg progress arc

  progressLabel: ($el, progress, model, options) =>
    if progress > 1
      $el.text("Done")
    else if progress <= 0.99
      $el.text("#{progress * 100}%").removeClass('processing')
    else
      $el.html("please wait").addClass('processing')
