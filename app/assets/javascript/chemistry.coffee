# Gem-provided JS
#= require hamlcoffee

# Node module JS
#= require jquery/dist/jquery
#= require underscore/underscore
#= require underscore.string/dist/underscore.string
#= require backbone/backbone
#= require backbone.marionette/lib/backbone.marionette
#= require backbone.stickit/backbone.stickit
#= require moment/moment
#= require smartquotes/dist/smartquotes
#= require balance-text/balancetext
#= require medium-editor/dist/js/medium-editor

# Chemistry JS
#= require './cms/application'
#= require './cms/config'
#= require_tree ./templates
#= require_tree ./cms/models
#= require_tree ./cms/collections
#= require_tree ./cms/views
#= require_self

$ ->
  _.mixin(s.exports())

  $.fn.chemistry = (options={}) ->
    @each ->
      args = _.extend options,
        el: @
      new Cms.Application(args).start()

  $('#chemistry').chemistry()