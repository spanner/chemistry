# Gem-provided JS
#= require hamlcoffee

# Node module JS
#= require underscore/underscore
#= require backbone/backbone
#= require backbone.marionette/lib/backbone.marionette
#= require backbone.stickit/backbone.stickit
#= require moment/moment
#= require smartquotes/dist/smartquotes
#= require balance-text/balancetext
#= require medium-editor/dist/js/medium-editor

# Local JS
#= require_tree ./templates
#= require_tree ./cms/models
#= require_tree ./cms/collections
#= require_tree ./cms/views
#= require_self

$ ->
  _.mixin(_.str.exports())

  $.fn.chemistry = (options={}) ->
    @each ->
      args = _.extend options,
        el: @
      new Cms.Application(args).start()
