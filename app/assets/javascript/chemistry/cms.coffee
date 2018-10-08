# Gem-provided JS
#= require hamlcoffee

# Framework
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

# UI helpers
#= require medium-editor/dist/js/medium-editor
#= require ./medium-editor-footnote
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
      new Cms.SiteEditor(args).start()

  $.fn.chemistry_page = (options={}) ->
    @each ->
      args = _.extend options,
        el: @
      new Cms.PageEditor(args).start()

  $.fn.chemistry_section = (options={}) ->
    @each ->
      args = _.extend options,
        el: @
      new Cms.SectionEditor(args).start()

  $.fn.chemistry_social = (options={}) ->
    @each ->
      args = _.extend options,
        el: @
      new Cms.SocialEditor(args).start()

  $.fn.chemistry_page_preview = (options={}) ->
    @each ->
      args = _.extend options,
        el: @
      new Cms.PagePreview(args).start()

  $('#chemistry.site').chemistry()
  $('#chemistry.page').chemistry_page()
  $('#chemistry.section').chemistry_section()
  $('#chemistry.social').chemistry_social()
  $('#chemistry.page_preview').chemistry_page_preview()
