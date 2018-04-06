class Cms.Views.Saver extends Cms.View
  template: 'helpers/saver'

  ui:
    save_button: "a.save"
    revert_button: "a.revert"
    publish_button: "a.publish"
    preview_button: "a.preview"
    config_button: "a.config"

  triggers:
    "click @ui.config_button": "config"

  events:
    "click @ui.save_button": "save"
    "click @ui.revert_button": "revertWithConfirmation"
    "click @ui.publish_button": "publishWithConfirmation"

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
    "a.preview":
      attributes: [
        name: "href"
        observe: "path"
        onGet: "absolutePath"
      ]
      classes: 
        available:
          observe: "published_at"

  onRender: =>
    super
    @ui.publish_button.hide() unless @model.is_a('Page')

  save: (e) =>
    e?.preventDefault()
    @model.save()

  revert: (e) =>
    e?.preventDefault()
    @model.revert()

  revertWithConfirmation: (e) =>
    e?.preventDefault()
    new Cms.Views.ReversionConfirmation
      model: @model
      link: @ui.revert_button
      action: @revert

  publish: =>
    e?.preventDefault()
    @model.publish()

  publishWithConfirmation: (e) =>
    e?.preventDefault()
    new Cms.Views.PublicationConfirmation
      model: @model
      link: @ui.publish_button
      action: @publish


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

  absolutePath: (path) =>
    if path[0] is '/' then path else "/#{path}"


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


## Toolbar
#
# Attaches an editing toolbar to a DOM element.
#
class Cms.Views.Toolbar extends Cms.View
  template: false
  className: "ed-toolbar"

  initialize: (opts={}) =>
    @target_el = opts.target

  onRender: () =>
    @_toolbar ?= new MediumEditor @target_el,
      placeholder: false
      autoLink: true
      imageDragging: false
      anchor:
        customClassOption: null
        customClassOptionText: 'Button'
        linkValidation: false
        placeholderText: 'URL...'
        targetCheckbox: false
      anchorPreview: false
      paste:
        forcePlainText: false
        cleanPastedHTML: true
        cleanReplacements: []
        cleanAttrs: ['class', 'style', 'dir']
        cleanTags: ['meta']
      toolbar:
        updateOnEmptySelection: true
        allowMultiParagraphSelection: true
        buttons: [
          name: 'bold'
          contentDefault: '<svg><use xlink:href="#bold_button"></use></svg>'
        ,
          name: 'italic'
          contentDefault: '<svg><use xlink:href="#italic_button"></use></svg>'
        ,
          name: 'anchor'
          contentDefault: '<svg><use xlink:href="#anchor_button"></use></svg>'
        ,
          name: 'orderedlist'
          contentDefault: '<svg><use xlink:href="#ol_button"></use></svg>'
        ,
          name: 'unorderedlist'
          contentDefault: '<svg><use xlink:href="#ul_button"></use></svg>'
        ,
          name: 'h2'
          contentDefault: '<svg><use xlink:href="#h1_button"></use></svg>'
        ,
          name: 'h3'
          contentDefault: '<svg><use xlink:href="#h2_button"></use></svg>'
        ,
          name: 'removeFormat'
          contentDefault: '<svg><use xlink:href="#clear_button"></use></svg>'
        ]