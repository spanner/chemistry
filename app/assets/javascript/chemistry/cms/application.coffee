Cms = {}
Cms.version = '0.2.0'
Cms.subtitle = "Beta 1"

Cms.Models = {}
Cms.Collections = {}
Cms.Views = {}

root = window
root.Cms = Cms


# The AppRouter maps routes onto UI function calls and their arguments.
# It is called on every change of window.location.
#
class Cms.AppRouter extends Backbone.Marionette.AppRouter
  appRoutes:
    "": "defaultView"
    ":collection_name": "collectionView"
    ":collection_name(?:qs)": "collectionView"
    ":model_name/:action/:id": "modelView"

  onRoute: (name, path, args) =>
    _cms.log "onRoute", name, path


# The Application is a supporting framework wrapped around the UI view.
# It provides navigation, rendering and API-interfacing services, and
# watches the window history stack. On every change of state it consults
# the AppRouter to select a UI function and pass arguments to it.
#
class Cms.Application extends Backbone.Marionette.Application
  defaults: {}

  initialize: (opts={}) ->
    @_original_backbone_sync = Backbone.sync
    @options = _.extend @defaults, opts
    @el = @options.el
    @_locale_ready = $.Deferred()
    @_data_ready = $.Deferred()
    @_config = new Cms.Config
    @_log_level = @_config.logLevel()
    @env = @_config.environment()
    @notices = new Cms.Collections.Notices
    @pages = new Cms.Collections.Pages
    @section_types = new Cms.Collections.SectionTypes
    @templates = new Cms.Collections.Templates
    @_available_locales = {}

    Backbone.sync = @sync
    Backbone.Marionette.Renderer.render = @render
    root.onerror = @reportError
    root._cms = @

  onStart: =>
    @preloadSite().done =>
      @setUILocale().done =>
        @_ui = new Cms.Views.UI el: @el
        @_ui.render()
        @_router = new Cms.AppRouter
          controller: @_ui
        Backbone.history.start
          pushState: true
          root: @config('mount_point')
        $(document).on "click", "a:not([data-bypass])", @handleLinkClick

  config: (key) =>
    @_config.get(key)

  apiUrl: =>
    @config('api_url')

  preloadSite: =>
    loader = $.getJSON @_config.initUrl()
    loader.done (data) =>
      # collections as nested jsonapi
      @templates.set data.templates, parse: true
      @section_types.set data.section_types, parse: true
      @pages.set data.pages, parse: true
      # locale urls as simple hash: should move to metadata?
      @_available_locales = data.locales
      @_data_ready.resolve(data)
    @_data_ready.promise()

  ## State changes
  #
  # Application state is URL-driven. Every URL change is passed to the router,
  # which parses the current window.location, chooses a UI function and passes
  # the route arguments to it.
  #
  # Link clicks are caught at the outer $el and the href passed to `navigate`.
  # We can also call `navigate` directly with a path, but that's very rare.
  #
  handleLinkClick: (e) ->
    $a = $(@)
    href = $a.attr("href")
    _cms.log "link click", href, @
    if href and href isnt "#" and href.slice(0, 4) isnt 'http'
      e.preventDefault()
      has_target = _.includes(href, "#")
      _cms.navigate href, trigger: !has_target

  navigate: (route, {trigger:trigger,replace:replace}={}) =>
    @log "navigate", route
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
      opts.attrs = model.toJSONWithRootAndAssociations()
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
      if JST["chemistry/#{template}"]
        JST["chemistry/#{template}"](data)
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
    @log "Complaint:", message
    @notify message, duration, 'error'

  notify: (html_or_text, duration=4000, notice_type='information') =>
    if @_ui
      @notices.add
        message: html_or_text
        duration: duration
        notice_type: notice_type
    else
      failure_notice = $('<div class="complete_failure" />').appendTo($("#notices"))
      failure_notice.html("<h2>Chemistry error</h2>" + html_or_text)
      $('.wait').hide()


  ## Localisation

  withLocale: (fn) =>
    @_locale_ready.done fn

  getUILocale: =>
    @_ui_locale

  chooseUILocale: =>
    if locale = @getQsParam('loc') or localStorage.getItem('chemistry_locale') or window.navigator.userLanguage or window.navigator.language or 'en'
      loc = locale.substr(0, 2)
    if @_available_locales[loc]
      loc
    else
      'en'

  setUILocale: (locale) =>
    resetting = !!@_ui_locale
    locale ?= @chooseUILocale()
    @log "setUILocale", locale, 'was', @_ui_locale
    unless @_ui_locale is locale
      if locale_url = @_available_locales[locale]
        @log "loading locale from", locale_url
        localStorage.setItem('chemistry_locale', locale)
        locale_loader = $.getJSON(locale_url)
        locale_loader.done (data) =>
          polyglot = new Polyglot()
          polyglot.extend(data)
          root.t = polyglot.t.bind(polyglot)
          @translationAvailable = polyglot.has.bind(polyglot)
          @_ui_locale = locale
          @_locale_ready.resolve(data)
          @_ui?.reset() if resetting
        locale_loader.fail (data, status, error) =>
          @complain("Locale file #{locale_url} could not be loaded: #{error}", 10000)
        @_locale_ready.promise()

  getQsParam: (key, qs) =>
    qs ||= window.location.search
    if qs
      params = new URLSearchParams(qs)
      params.get(key)


  ## Logging
  #todo: log level threshold
  #
  log: =>
    if console?.log? and @logging()
      console.log "⚗️", arguments...

  logging: (level) =>
    !!@_log_level

  startLogging: (level) =>
    @_log_level = level ? 'info'

  stopLogging: (level) =>
    @_log_level = null
