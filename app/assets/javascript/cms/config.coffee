## Configuration
#
# The Config is a simple config-by-environment mechanism. It's only one level deep:
# basically a list of default settings that can be overridden for each environment,
# and some regexes for detecting the environment in which we are running.

# TODO make this configurable at the rails application level

class Cms.Config
  defaults: 
    auth_url: "https://stemnet.hk/users"
    api_url: "https://stemnet.hk/api"
    mount_point: "/chemistry"
    cookie_name: "_stemnet_auth"
    cookie_domain: ".stemnet.hk"
    logging: false
    trap_errors: true
    display_errors: false
    badger_errors: true

  production:
    auth_url: "https://stemnet.hk/users"
    api_url: "https://stemnet.hk/api"

  staging:
    auth_url: "http://staging.stemnet.hk/users"
    api_url: "http://staging.stemnet.hk/api"
    logging: true
    log_level: 'info'

  development:
    api_url: "https://api.vwl.dev/chemistry"
    cookie_domain: ".vwl.dev"
    logging: true
    log_level: 'debug'
    display_errors: true
    badger_errors: false
    trap_errors: false

  constructor: (options={}) ->
    @_environment = options.environment ? @guessEnvironment()
    @_settings = _.defaults options, @[@_environment], @defaults

  guessEnvironment: () ->
    stag = new RegExp(/staging/)
    dev = new RegExp(/\.dev/)
    href = window.location.href
    if stag.test(href)
      "staging"
    else if dev.test(href)
      "development"
    else
      "production"

   settings: =>
     @_settings

   get: (key) =>
    @_settings[key]

   set: (key, value) =>
    @_settings[key] = value

  environment: =>
    @_environment ?= @guessEnvironment()

  logLevel: =>
    @_settings['log_level'] ? 'info'
