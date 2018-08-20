# The EditableSomethings are wrapped around existing html content to overlay editing tools of various kinds.

class Cms.Views.EditableHtml extends Cms.View
  template: false

  initialize: ->
    super
    @render()

  onRender: =>
    @$el.attr('contenteditable', 'true')
    super

    #TODO v2 moves contenteditable down to the block level element, manage that list.
    @$el.find('figure.image').each (i, el) =>
      @addView new Cms.Views.Image
        el: el
    @$el.find('figure.video').each (i, el) =>
      @addView new Cms.Views.Video
        el: el
    @$el.find('figure.quote').each (i, el) =>
      @addView new Cms.Views.Quote
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

    @$el.on "focus", @ensureP
    @$el.on "blur", @clearP

  ## Contenteditable helpers
  # Small interventions to make contenteditable behave in a slightly saner way,
  # eg. by definitely typing into an (apparently) empty <p> element.
  #
  ensureP: (e) =>
    el = e.target
    if el.innerHTML is ""
      el.style.minHeight = el.offsetHeight + 'px'
      p = document.createElement('p')
      p.innerHTML = "&#8203;"
      el.appendChild p

  clearP: (e) =>
    el = e.target
    content = el.innerText.trim()
    el.innerHTML = "" if !content or content is "&#8203;" or content is "​"  # there's a zwsp in that

  # called when an embedded asset view gives us an 'update' event
  onUpdate: =>
    @$el.trigger 'input'


class Cms.Views.EditableString extends Cms.View
  template: false

  initialize: ->
    super
    @render()

  onRender: =>
    @$el.attr('contenteditable', 'true')
    #todo formatting toolbar only
    @_toolbar = new Cms.Views.Toolbar
      target: @$el
    @_toolbar.render()


class Cms.Views.EditableBackground extends Cms.View
  template: false

  ui:
    bg: "figure.bg"

  initialize: ->
    super
    @render()

  onRender: =>
    if @ui.bg.length
      bg_el = @ui.bg.first()
    else
      bg_el = $('<figure class="bg"></figure>').appendTo(@el)
    @addView new Cms.Views.Background
      el: bg_el

  # Update is called when our embedded background view triggers an 'update' event
  # Unlike most editables, our element is not a bound contenteditable so we can't just populate it and trigger 'input'
  # We have to assume that it is the background_html attribute we should update, and do that directly.
  #
  onUpdate: =>
    @log "🚜 background onUpdate"
    @model.set "background_html", @withoutControls(@$el.html())

