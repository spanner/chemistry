## Standard public js
#
# A small collection of JS sprinkles required to bring chemistry pages to life:
# * cms overlay when signed in
# * enquiry forms
# * contents lists
# * footnote placement

$ ->

  $.fn.cms_menu = ->
    @each ->
      $article = $(@)
      path = $article.data('page')
      fetcher = $.ajax
        method: "get"
        url: "/cms/page_controls/#{path}"
      fetcher.done (response) =>
        $article.prepend response


  ## Footnotes

  $.fn.footnoted = ->
    @each ->
      new Footnote(@)


  class Footnote
    constructor: (element) ->
      $link = $(element)

      @_key = $link.attr('href').replace('#footnote-', '')
      @_number = $('a[data-fn]').length + 1
      $link.attr "data-fn", @_number

      @$article = $link.parents('article').first()
      @$editable = $link.parents('[contenteditable]').first()

      @placeFootnote()
      @$editable.on 'input', @placeFootnote
      $(document).on 'page_update', @placeFootnote
      $(window).on 'resize', @placeFootnote

    placeFootnote: =>
      $link = $("#link-#{@_key}")
      $footnote = $("#footnote-#{@_key}")

      $footnote.attr "data-fn", @_number

      link_offset = $link.position()
      if @$article.hasClass('wide')
        $footnote.css 'left', link_offset.left

      else if @$article.hasClass('long')
        $footnote.css 'top', link_offset.top


  ## Enquiry form

  $.fn.enquiry_form = ->
    @each ->
      new EnquiryForm(@)


  class EnquiryForm
    constructor: (element) ->
      @$container = $(element)
      @$form = @$container.find('form')
      @$confirmation = @$container.find('.confirmation')

      @$message = @$form.find('textarea')
      @$name = @$form.find('input[type="text"]')
      @$email = @$form.find('input[type="email"]')
      @$submit = @$form.find('input[type="submit"]')
      @$error = @$form.find('.error')
      @_email_re = /^([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})$/i

      @$confirmation.hide()
      @$form.on 'submit', @doForm
      @$name.on 'input', @validate
      @$email.on 'input', @validate
      @$message.on 'input', @validate
      @validate()

    validate: =>
      name = @$name.val()
      email = @$email.val()
      message = @$message.val()
      if name and message and @emailLooksVaguelyOk(email)
        @$submit.attr 'disabled', false
      else
        @$submit.attr 'disabled', true

    emailLooksVaguelyOk: (email) =>
      email and email.match(@_email_re)

    doForm: (e) =>
      e?.preventDefault()
      @$submit.addClass('waiting')
      action = @$form.attr('action') or "/cms/api/enquiries/enquire"
      console.log "doForm", action
      name = @$name.val()
      email = @$email.val()
      message = @$message.val()
      enquiry = $.ajax
        url: action
        method: "post"
        dataType: "json"
        data:
          enquiry:
            name: name
            email: email
            message: message
      enquiry.done @acknowledgeEnquiry
      enquiry.fail @mumbleApologetically

    acknowledgeEnquiry: (response) =>
      console.log "acknowledgeEnquiry", response, @$confirmation
      @$form.fadeOut =>
        @$confirmation.fadeIn()

    mumbleApologetically: () =>


  ## Contents list

  $.fn.contents_list = (path) ->
    @each ->
      new ContentsList(@, path)


  class ContentsList
    constructor: (element, path, limit) ->
      @$container = $(element)
      @_page_path = path or @$container.data('contents') or window.location.pathName
      @_page_size = limit or @$container.data('limit')
      @fetchPage()

    fetchPage: =>
      url = new URL(window.location.href)
      params = new URLSearchParams(url.search)
      api_path = "/cms/contents/#{@_page_path}"
      params.set('limit', @_page_size) if @_page_size and not params.get('limit')
      if qs = params.toString()
        api_path += '?' + qs
      waiter = $('<li class="waiter">Loading pages</li>')
      @$container.append waiter
      $.get(api_path).done @display

    display: (response) =>
      @$container.find('.waiter').fadeOut 'fast', =>
        @$container.html(response).fadeIn()
        @$container.find('a.fetch').click @refetch

    refetch: (e) =>
      if e
        e.preventDefault()
        if a = e.target
          #TODO this is a bit clunky. We should have one place where we work out the new URL and enact it.
          href = a.href.replace('/cms/contents', '')
          a_href = new URL(href)
          window.history.pushState {}, "", decodeURIComponent(a_href)
          @fetchPage()



  $.fn.latest_list = (path, limit) ->
    @each ->
      new LatestList(@, path)

  class LatestList
    constructor: (element, path, limit) ->
      @$container = $(element)
      @_page_path = path or @$container.data('page') or window.location.pathName
      @_page_size = limit or @$container.data('limit')
      @fetchPage()

    fetchPage: =>
      api_path = "/cms/latest/#{@_page_path}"
      api_path += "?limit=#{@_page_size}" if @_page_size
      waiter = $('<li class="waiter">Loading pages</li>')
      @$container.append waiter
      $.get(api_path).done @display

    display: (response) =>
      @$container.find('.waiter').fadeOut 'fast', =>
        @$container.html(response).fadeIn()



  # $('article[data-page]').cms_menu()
  $('section.enquiry').enquiry_form()
  $('[data-contents]').contents_list()
  $('a.footnoted').footnoted()
