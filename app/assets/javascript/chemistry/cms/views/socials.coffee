class Cms.Views.Social extends Cms.View
  template: 'socials/social'
  tagName: "li"

  ui:
    input: 'input[type="text"]'
    prompt: 'span.prompt'
    name: 'span.name'
    save: 'a.save'
    cancel: 'a.cancel'
    add: 'a.add'
    remove: 'a.remove'

  events:
    "keydown @ui.name": "catchControlKey"
    "click @ui.name": "edit"
    "click @ui.save": "save"
    "click @ui.cancel": "cancelEdit"
    "click @ui.add": "addSimilar"
    "click @ui.remove": "remove"

  bindings:
    ":el":
      classes:
        persisted: "id"
    "use.platform":
      attributes: [
        name: "xlink:href"
        observe: "platform"
        onGet: "platformSymbol"
      ]
    "span.name":
      observe: "url"
      classes:
        editing: "editing"
    "span.prompt":
      attributes: [
        name: "class"
        observe: "platform"
      ]
    "a.add":
      observe: ["id", "editing"]
      visible: "ifSavedAndNotEditing"
    "a.remove":
      observe: ["id", "editing"]
      visible: "ifSavedAndNotEditing"
    "a.save":
      observe: ["url", "editing"]
      visible: "ifSaveable"
    "a.cancel":
      observe: "editing"
      visible: "ifEditing"

  initialize: =>
    @collection = @model.collection

  onRender: =>
    @stickit()
    @ui.name.attr "placeholder", @defaultName()

  platformSymbol: (platform) =>
    "##{platform}_symbol"

  defaultName: (platform) =>
    #todo i18n
    platform ?= @model.get("platform")
    switch platform
      when "facebook"
        "Facebook page name"
      when "twitter"
        "Twitter handle"
      when "instagram"
        "Instagram handle"

  edit: (e) =>
    e?.preventDefault()
    @_previous_url = @model.get('url')
    @model.set 'editing', true
    @ui.name.attr('contenteditable', true).focus()

  cancelEdit: (e) =>
    e?.preventDefault()
    @model.set
      url: @_previous_url
      editing: false
    @ui.name.removeAttr('contenteditable')

  catchControlKey: (e) =>
    kc = e.keyCode
    if kc is 13
      @save(e)
    else if kc is 27
      @cancelEdit(e)

  save: (e) =>
    e?.preventDefault()
    if @model.get('url').length
      @model.set
        editing: false
      @model.save().done =>
        @$el.signal_confirmation()

  ifSavedAndNotEditing: ([id, editing]=[]) =>
    id and not editing

  ifEditing: (editing) =>
    !!editing

  ifSaveable: ([url, editing]=[]) =>
    url and editing

  addSimilar: =>
    @collection.add({platform: @model.get('platform')}, {at: @collection.indexOf(@model) + 1})

  remove: =>
    @$el.fadeOut 'fast', =>
      @model.destroy()


#todo: how to allow local markup around this list?
#
class Cms.Views.SocialsManager extends Cms.CompositeView
  template: 'socials/manager'
  childViewContainer: "ul.socials"
  childView: Cms.Views.Social

  ui:
    heart: "a.like"
    popup: ".socialiser"
    fieldsets: "fieldset.social"
    controls: ".controls"
    closer: "a.close"

  events:
    "click a.like": "togglePopup"
    "click a.close": "hidePopup"

  initialize: =>
    @collection.fetch().done =>
      @render()

  togglePopup: (e) =>
    if @$el.hasClass('up')
      @hidePopup(e)
    else
      @showPopup(e)

  showPopup: (e) =>
    e?.preventDefault()
    @$el.addClass('up')

  hidePopup: (e) =>
    e?.preventDefault()
    @$el.removeClass('up')
