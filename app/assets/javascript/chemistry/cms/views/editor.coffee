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

