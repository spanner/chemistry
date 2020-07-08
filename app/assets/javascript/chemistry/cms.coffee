
$ ->
  _.mixin(s.exports())
  document.execCommand('defaultParagraphSeparator', false, 'p')

  $.fn.chemistry_site = (options={}) ->
    @each ->
      args = _.extend options,
        el: @
      new Cms.SiteEditor(args).start()

  $.fn.chemistry_page_builder = (options={}) ->
    @each ->
      args = _.extend options,
        el: @
      new Cms.PageBuilder(args).start()


  $('#chemistry.site_editor').chemistry_site()
  $('#chemistry.page_builder').chemistry_page_builder()
