# Enquiry view
#
class Cms.Views.Enquiry extends Cms.ItemView
  template: "enquiries/enquiry"
  className: "enquiry"

  events:
    "click a.dismiss": "dismiss"

  bindings:
    ":el":
      classes:
        unsaved: "changed"
        unpublished: "unpublished"
    "a.dismiss":
      observe: "closed_at"
      visible: "untrue"
    ".response":
      observe: "closed_at"
      visible: "untrue"
    ".name":
      observe: "name"
    "date":
      observe: "created_at"
      onGet: "niceDatetime"
    ".email":
      observe: "email"
      attributes: [
        name: "href"
        observe: "email"
        onGet: "mailtoHref"
      ]
    ".message":
      observe: "message"
      onGet: "simpleFormat"
      updateMethod: "html"
    "a.email":
      attributes: [
        name: "href"
        observe: "email"
        onGet: "mailtoWithSubject"
      ]

  onRender: =>
    super
    window.enq = @model

  dismiss: (e) =>
    e?.preventDefault()
    @model.dismiss().done =>
      _cms.navigate "/enquiries#enquiry_#{@model.get('id')}"

  mailtoWithSubject: (email) =>
    subject = encodeURIComponent(t("enquiries.response_subject"))
    "mailto:#{email}?subject=#{subject}"

  simpleFormat: (text) =>
    cleaner = $('<div />')
    paragraphs = text.split(/\n\n+/)
    html = paragraphs.map (p) ->
      p = cleaner.html(p).text().replace(/([^\n]\n)(?=[^\n])/g, '$1<br>')
      "<p>#{p}</p>"
    html.join("\n")

  quoted: (text) =>
    paragraphs = text.split(/\n\n+/).map (p) -> "> #{p}"
    paragraphs.join("\n>\n")


# Enquiry list
#
class Cms.Views.ListedEnquiry extends Cms.Views.ListedView
  template: "enquiries/listed"
  className: "enquiry"

  events:
    "click a.complete": "completed"

  bindings:
    ":el":
      classes:
        dismissed: "closed_at"
        seen: "seen_at"
      attributes: [
        name: "id"
        observe: "id"
        onGet: "enquiryId"
      ]
    "a.enquiry":
      attributes: [
        name: "href"
        observe: "id"
        onGet: "showMeHref"
      ]
    ".name":
      observe: "name"
      onGet: "shortName"
    ".email":
      observe: "email"
    "date":
      observe: "created_at"
      onGet: "niceDatetime"
    ".message":
      observe: "message"
      onGet: "shortMessage"

  enquiryId: (id) =>
    "enquiry_#{id}"

  #todo: sanitize
  shortName: (name) =>
    @shortAndClean(name, 48)

  shortMessage: (message) =>
    @shortAndClean(message, 96)

  completed: (e) =>
    e?.preventDefault()
    @model.completed()


class Cms.Views.Enquiries extends Cms.CollectionView
  childView: Cms.Views.ListedEnquiry
  tagName: "ul"
  className: "enquiries"


class Cms.Views.EnquiriesIndex extends Cms.Views.IndexView
  template: "enquiries/index"

  regions:
    enquiries:
      el: "#enquiries"

  events:
    "click a.new.enquiry": "testEnquiry"

  initialize: ->
    @collection.load()
    @render()

  onRender: =>
    super
    enquiry_list = new Cms.Views.Enquiries
      collection: @collection
    @getRegion('enquiries').show enquiry_list

