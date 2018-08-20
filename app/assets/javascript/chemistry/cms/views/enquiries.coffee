# Enquiry view
#
class Cms.Views.Enquiry extends Cms.View
  template: "enquiries/enquiry"

  events:
    "click a.complete": "completed"

  bindings:
    ":el":
      classes:
        unsaved: "changed"
        unpublished: "unpublished"
    ".name":
      observe: "name"
      onGet: "shortName"
    ".email":
      observe: "email"
      attributes: [
        name: "href"
        observe: "email"
        onGet: "mailtoHref"
      ]
    ".message":
      observe: "message"
      onGet: "shortMessage"

  completed: (e) =>
    e?.preventDefault()
    @model.completed()


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
        unsaved: "changed"
        unpublished: "unpublished"
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

  #todo: sanitize
  shortName: (name) =>
    @shortAndClean(name, 48)

  shortMessage: (message) =>
    @shortAndClean(message, 96)

  mailtoHref: (email) =>
    "mailto:#{email}"

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

