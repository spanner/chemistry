# The EditableSomethings are wrapped around existing html content to overlay editing tools of various kinds.


class Cms.Views.EditableHelper extends Cms.View
  template: ""

  initialise: =>
    @$el.attr('contenteditable', 'true')
    super

  # note whole render mechanism replaced here. Marionette no-ops render when template is false,
  # while we want to reach a 'rendered' state without replacing any DOM elements.
  #
  render: =>
    @bindUIElements()
    @triggerMethod 'render'


class Cms.Views.EditableHtml extends Cms.Views.EditableHelper

  onRender: =>
    #TODO v2 will move contenteditable property down to the block level element, manage that list and observe its mutations.
    @$el.find('figure.image').each (i, el) =>
      @addView new Cms.Views.Image
        el: el
    @$el.find('figure.video').each (i, el) =>
      @addView new Cms.Views.Video
        el: el
    @$el.find('figure.quote').each (i, el) =>
      @addView new Cms.Views.Quote
        el: el
    @$el.find('figure.linkbutton').each (i, el) =>
      @addView new Cms.Views.LinkButton
        el: el
    @$el.find('figure.document').each (i, el) =>
      @addView new Cms.Views.Document
        el: el
    @$el.find('aside.note').each (i, el) =>
      @addView new Cms.Views.Note
        el: el

    toolbar = @$el.data('cms-toolbar') or ""
    if toolbar_class = Cms.Views[toolbar.charAt(0).toUpperCase() + toolbar.slice(1) + "Toolbar"]
      @_toolbar = new toolbar_class
        target: @$el
      @_toolbar.render()

    if @$el.data('cms-assets')
      @_inserter = new Cms.Views.AssetInserter
        target: @
      @_inserter.render()

    @$el.on "activate", @ensureP
    @$el.on "focus", @ensureP
    @$el.on "blur", @clearP

  # called when an embedded asset view gives us an 'update' event
  onUpdate: =>
    @$el.trigger 'input'


class Cms.Views.EditableString extends Cms.Views.EditableHelper
  template: ""


class Cms.Views.EditableBackground extends Cms.Views.EditableHelper
  template: ""

  ui:
    bg: "figure.bg"

  onRender: =>
    @log "onRender with bg", @ui.bg
    if @ui.bg.length
      bg_el = @ui.bg.first()
    else
      bg_el = $('<figure class="bg"></figure>').appendTo(@el)
    @addView new Cms.Views.Background
      el: bg_el

  # Update is called when our embedded background view triggers an 'update' event
  # Unlike most editables, our element is not a bound contenteditable so we can't just populate it and trigger 'input'
  # We assume that it is the `background_html` attribute we should update, and do that directly.
  #
  onUpdate: =>
    html = @withoutControls(@$el.html())
    @log "onUpdate", @model.id, @model.cid, html
    @model.set "background_html", html


