Cms = {}
Cms.version = '0.2.0'
Cms.subtitle = "Beta 1"

Cms.Models = {}
Cms.Collections = {}
Cms.Views = {}

root = exports ? this
root.Cms = Cms


# The AppRouter maps routes onto UI function calls and their arguments.
# It is called on every change of window.location.
#
class Cms.AppRouter extends Backbone.Marionette.AppRouter
  appRoutes:
    "": "dashboardView"
    ":base": "contentView"
    ":base/:id": "contentView"
    ":base/:id(?:qs)": "contentView"


# The Application is a supporting framework wrapped around the UI view.
# It provides navigation, rendering and API-interfacing services, and
# watches the window history stack. On every change of state it uses the
# AppRouter to select a UI function and pass arguments to it.
#
class Cms.Application extends Backbone.Marionette.Application
  defaults: {}

  initialize: (opts={}) ->
    @_original_backbone_sync = Backbone.sync
    @options = _.extend @defaults, opts
    @el = @options.el
    @_loaded = $.Deferred()
    @_config = new Cms.Config
    @_log_level = @_config.logLevel()
    @env = @_config.environment()
    @images = new Cms.Collections.Images
    @videos = new Cms.Collections.Videos
    @documents = new Cms.Collections.Documents
    @notices = new Cms.Collections.Notices
    Backbone.sync = @sync
    Backbone.Marionette.Renderer.render = @render
    root.onerror = @reportError
    root._cms = @

  onStart: =>
    @_ui = new Cms.Views.UI
      el: @el
    @_ui.render()
    @_router = new Cms.AppRouter
      controller: @_ui
    Backbone.history.start
      pushState: true
    $(document).on "click", "a:not([data-bypass])", @handleLinkClick

  config: (key) =>
    @_config.get(key)

  apiUrl: =>
    @config('api_url')


  ## State changes
  #
  # Application state is URL-driven. Every URL change is passed to the router,
  # which parses the current window.location, chooses a UI function and passes
  # the route arguments to it.
  #
  # Link clicks are caught at the outer $el and the href passed to `navigate`.
  # We can also call `navigate` directly with a path, but that's very rare.
  #
  handleLinkClick: (e) =>
    $a = $(e.originalEvent.target)
    href = $a.attr("href")
    if href and href isnt "#" and href.slice(0, 4) isnt 'http'
      e.preventDefault()
      has_target = _.str.contains(href, "#")
      @navigate href, trigger: !has_target

  navigate: (route, {trigger:trigger,replace:replace}={}) =>
    trigger ?= true
    replace ?= false
    Backbone.history.navigate route,
      trigger: trigger
      replace: replace


  ## Overrides
  #
  # We override Backbone.sync to add a progress listener to every save.
  #
  sync: (method, model, opts) =>
    unless method is "read"
      original_success = opts.success
      model.startProgress()
      opts.beforeSend = (xhr, settings) ->
        settings.xhr = () ->
          xhr = new window.XMLHttpRequest()
          xhr.upload.addEventListener "progress", (e) ->
            model.setProgress e
          , false
          xhr
      opts.success = (data, status, request) ->
        model.finishProgress(true)
        original_success(data, status, request)
    @_original_backbone_sync method, model, opts

  # Render uses our hamlcoffee templates through JST
  #
  render: (template, data={}) =>
    if _.isFunction(template)
      template = template()
    if template?
      if JST[template]
        JST[template](data)
      else
        template
    else
      ""


  ## Confirmation and error messages
  #
  # `notify` puts a message on the job queue and returns the relevant announcement,
  # which is a job that can have progress callbacks and other listeners attached to it.
  #
  # In production, all errors are trapped and reported to honeybadger, in the hope that 
  # the ui will remain responsive.
  #
  reportError: (message, source, lineno, colno, error) =>
    complaint = "<strong>#{message}</strong> at #{source} line #{lineno} col #{colno}."
    if @config('display_errors')
      @complain(complaint, 60000)
    if @config('badger_errors')
      Honeybadger.notify error,
        message: complaint
    true if @config('trap_errors')

  confirm: (message, duration=4000) =>
    @notify message, duration, 'confirmation'

  complain: (message, duration=10000) =>
    @notify message, duration, 'error'

  notify: (html_or_text, duration=4000, notice_type='information') =>
    if @_notice_list
      @notices.add
        message: html_or_text
        duration: duration
        notice_type: notice_type
    else
      failure_notice = $('<div class="complete_failure" />').appendTo($("#notices"))
      failure_notice.html("<h2>System failure</h2>" + html_or_text)
      $('.wait').hide()


  ## Logging
  #todo: log level threshold
  #
  log: =>
    if console?.log? and @logging()
      console.log "[amp]", arguments...

  logging: (level) =>
    !!@_log_level

  startLogging: (level) =>
    @_log_level = level ? 'info'

  stopLogging: (level) =>
    @_log_level = null
