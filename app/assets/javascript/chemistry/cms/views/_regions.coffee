## Floating overlays
#  are handled by a custom region class that does the floating part.
#
class Cms.FloatingRegion extends Backbone.Marionette.Region

  onShow: (region, view, options={}) =>
    @log "FloatingRegion onShow", options
    if $over = options.over
      offset = $over.offset()
      default_adjustment =
        top: -20
        left: -20
      offset_offset = options.offset or default_adjustment
      @$el.css
        top: offset.top + offset_offset.top
        left: offset.left + offset_offset.left
    view.on 'close', => @reset()
    @$el.addClass 'up'

  removeView: (view) =>
    @log "FloatingRegion removeView"
    @$el.removeClass 'up'
    _.delay =>
      @destroyView view
    , 500

  log: ->
    _cms.log "[#{@constructor.name}]", arguments...


class Cms.Views.FloatingView extends Cms.View

  triggers:
    "click a.close": "close"
    "click a.cancel": "close"
