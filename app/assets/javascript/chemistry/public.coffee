## Standard public js
#
# A very minimal collection of JS sprinkles required to bring chemistry pages to life:
# * cms overlay when signed in
# * enquiry forms
# * contents lists
# * footnote placement

jQuery ($) ->

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


  window.FN = Footnote


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
      action = @$form.attr('action') or "/chemistry/enquiries/enquire"
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


$ ->
  $('section.enquiry').enquiry_form()
  $('a.footnoted').footnoted()
