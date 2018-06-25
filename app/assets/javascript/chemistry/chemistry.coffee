# Gem-provided JS
#= require hamlcoffee

# Node module JS
#= require jquery/dist/jquery
#= require node-polyglot/build/polyglot
#= require underscore/underscore
#= require underscore.string/dist/underscore.string
#= require backbone/backbone
#= require backbone.marionette/lib/backbone.marionette
#= require backbone.stickit/backbone.stickit
#= require moment/moment
#= require smartquotes/dist/smartquotes
#= require balance-text/balancetext
#= require medium-editor/dist/js/medium-editor
#= require ep-jquery-tokeninput/src/jquery.tokeninput
#= require air-datepicker/dist/js/datepicker
#= require air-datepicker/dist/js/i18n/datepicker.en

# Chemistry JS
#= require ./cms/application
#= require ./cms/config
#= require_tree ../templates/chemistry
#= require_tree ./cms/models
#= require_tree ./cms/views
#= require_self

$ ->
  _.mixin(s.exports())
  document.execCommand('defaultParagraphSeparator', false, 'p')

  $.fn.chemistry = (options={}) ->
    @each ->
      args = _.extend options,
        el: @
      new Cms.Application(args).start()

  $('#chemistry').chemistry()