# The editor is wrapped around existing html content.
# It has two jobs: to make embedded assets editable,
# and to attach an asset-inserter that will add more.

class Cms.Views.Editor extends Cms.View
  template: false

  initialize: ->
    @render()

  onRender: =>
    @log "render", @el
    @$el.find('figure.image').each (i, el) =>
      @addView new Cms.Views.Image
        el: el
    @$el.find('figure.video').each (i, el) =>
      @addView new Cms.Views.Video
        el: el
    @$el.find('figure.quote').each (i, el) =>
      @addView new Cms.Views.Quote
        el: el
    # @$el.find('div.annotation').each (i, el) =>
    #   @addView new Cms.Views.Annotation
    #     el: el

    @_inserter = new Cms.Views.AssetInserter
      target: @$el
    @_inserter.render()

    @$el.on "focus", @ensureP
    @$el.on "blur", @removeEmptyP


## Asset inserter
#
# This view inserts a new asset element into the html stream with a management view wrapped around it.
#
class Cms.Views.AssetInserter extends Cms.View
  template: "assets/inserter"
  tagName: "div"
  className: "cms-inserter"

  events:
    "click a.show": "toggleButtons"
    "click a.image": "addImage"
    "click a.video": "addVideo"
    "click a.quote": "addQuote"
    "click a.quote": "addAnnotation"

  initialize: (@options={}) ->
    @log "init", @options
    @_target_el = @options.target
    @_p = null

  onRender: () =>
    @log "onRender"
    @$el.appendTo _cms.el
    @_target_el.on "click keyup focus", @followCaret

  followCaret: (e)=>
    @log "followCaret"
    selection = @el.ownerDocument.getSelection()
    if !selection or selection.rangeCount is 0
      current = $(e.target)
    else
      range = selection.getRangeAt(0)
      current = $(range.commonAncestorContainer)
    @_p = current.closest('p')
    text = @_p.text()
    if @_p.length and _.isBlank(text) or text is "​" # zwsp!
      @log "showing", @el
      @show(@_p)
    else
      @log "not showing:", @_p.text().length
      @hide()

  toggleButtons: (e) =>
    e?.preventDefault()
    if @$el.hasClass('showing')
      @trigger 'contract'
      @$el.removeClass('showing')
    else
      @trigger 'expand'
      @$el.addClass('showing')

  addImage: =>
    @insert new Cms.Views.Image

  addVideo: =>
    @insert new Cms.Views.Video

  addQuote: =>
    @insert new Cms.Views.Quote

  addButton: =>
    @insert new Cms.Views.Button

  addBlocks: =>
    @insert new Cms.Views.Blocks

  insert: (view) =>
    if @_p
      @_p.before view.el
      # @_p.remove() if @isBlank(@_p.text())
    else
      @_target_el.append view.el
      @_target_el.append $("<p />")
    view.render()
    view.focus?()
    # @_target_el.trigger 'input'
    @hide()

  place: ($el) =>
    position = $el.offset()
    @$el.css
      top: position.top - 6
      left: position.left - 40

  show: () =>
    @place(@_p)
    @$el.show()

  hide: () =>
    @$el.hide()
    @$el.removeClass('showing')

