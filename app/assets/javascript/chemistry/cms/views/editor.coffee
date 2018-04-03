# The editors are wrapped around existing html content
# to provide the right tools for editing it.

class Cms.Views.StringEditor extends Cms.View
  template: false

  initialize: ->
    super
    @render()

  onRender: =>
    # @$el.attr('contenteditable', 'plaintext-only').addClass('editing')


class Cms.Views.HtmlEditor extends Cms.View
  template: false

  initialize: ->
    super
    @render()

  onRender: =>
    @$el.find('figure.image').each (i, el) =>
      @addView new Cms.Views.Image
        el: el
    @$el.find('figure.video').each (i, el) =>
      @addView new Cms.Views.Video
        el: el
    @$el.find('figure.quote').each (i, el) =>
      @addView new Cms.Views.Quote
        el: el
    @$el.find('aside.note').each (i, el) =>
      @addView new Cms.Views.Note
        el: el

    @_inserter = new Cms.Views.AssetInserter
      target: @$el
    @_inserter.render()

    @$el.on "focus", @ensureP
    @$el.on "blur", @removeEmptyP

  ## Contenteditable helpers
  # Hacky intervention to make contenteditable behave in a slightly saner way,
  # eg. by definitely typing into an (apprently) empty <p> element.
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


class Cms.Views.BackgroundImageEditor extends Cms.View
  template: false

  initialize: ->
    super
    @render()

  onRender: =>
    unless @$el.find('figure.bg').length
      $('<figure class="bg"></figure>').appendTo @el
    @$el.attr('contenteditable', 'true').addClass('editing')
    @$el.find('figure.bg').each (i, el) =>
      @addView new Cms.Views.BackgroundImage
        el: el


    # bindings are not set up correctly because we bind primary before the contenteditable attribute is added