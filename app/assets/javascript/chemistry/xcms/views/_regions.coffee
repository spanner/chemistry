## Floating overlays
#  are handled by a custom region class that does the floating part.
#
class Cms.FloatingRegion extends Marionette.Region

  onShow: (region, view, options={}) =>
    @log "FloatingRegion onShow", options
    if $over = options.over
      offset = $over.offset()
      default_adjustment =
        top: -20
        left: -20
      offset_offset = options.offset or default_adjustment
      offset_css =
        top: offset.top + offset_offset.top
        left: offset.left + offset_offset.left
      @log "Offsetting floater", $over.offsetParent(), @$el.offsetParent()
      @$el.css offset_css
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


class Cms.FadingRegion extends Marionette.Region

  attachHtml: (view) =>
    view.$el
      .css({display: 'none'})
      .appendTo(@$el)
    view.$el.fadeIn() unless @isSwappingView()

  removeView: (view) =>
    view.$el.fadeOut 'slow', =>
      @destroyView(view)
      @currentView.$el.fadeIn() if @currentView

