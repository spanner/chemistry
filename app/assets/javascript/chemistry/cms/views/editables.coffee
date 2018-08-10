# The EditableSomethings are wrapped around existing html content to overlay editing tools of various kinds.

class Cms.Views.EditableHtml extends Cms.View
  template: false

  initialize: ->
    super
    @render()

  onRender: =>
    @$el.attr('contenteditable', 'true')
    super

  onReady: =>
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

    @_toolbar = new Cms.Views.Toolbar
      target: @$el
    @_toolbar.render()

    @_inserter = new Cms.Views.AssetInserter
      target: @$el
    @_inserter.render()

    @$el.on "focus", @ensureP
    @$el.on "blur", @removeEmptyP

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
    content = el.innerHTML
    el.innerHTML = "" if content is "<p>&#8203;</p>" or content is "<p><br></p>" or content is "<p>​</p>"  # there's a zwsp in that last string

  # update is called when an embedded asset view triggers an 'update' event
  onUpdate: =>
    @$el.trigger 'input'


class Cms.Views.EditableString extends Cms.View
  template: false

  initialize: ->
    super
    @render()

  onRender: =>
    @$el.attr('contenteditable', 'true')
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
    @model.set "background_html", @withoutControls(@$el.html())


