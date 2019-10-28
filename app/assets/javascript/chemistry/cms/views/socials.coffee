class Cms.Views.Social extends Cms.View
  template: 'socials/edit'
  tagName: "li"

  ui:
    prompt: 'span.prompt'
    name: 'span.name'
    url: 'span.url'
    save: 'a.save'
    cancel: 'a.cancel'
    add: 'a.add'
    remove: 'a.remove'

  events:
    "keydown @ui.name": "catchControlKey"
    "click @ui.remove": "remove"
    "click @ui.add": "addSimilar"

  bindings:
    ":el":
      classes:
        persisted: "id"
        populated: "url"
        editing: "editing"
    "use.platform":
      attributes: [
        name: "xlink:href"
        observe: "platform"
        onGet: "platformSymbol"
      ]
    "span.name":
      observe: "name"
      onSet: "withoutHTML"
      onGet: "withoutHTML"
    "span.url":
      observe: "url"
      onSet: "withoutHTML"
      onGet: "withoutHTML"
    "a.add":
      observe: "url"
      visible: true

  initialize: (opts={}) ->
    super
    @_platform = opts.platform
    @_collection = opts.collection

  onRender: =>
    @model.on 'focus', @onFocus
    @stickit()
    @$el.addClass(@_platform)
    @ui.url.attr "data-placeholder", @defaultUrl()
    @ui.name.attr "data-placeholder", @defaultName()

  platformSymbol: (platform) =>
    "##{platform}_symbol"

  defaultUrl: (platform) =>
    #todo: i18n
    platform ?= @model.get("platform")
    switch platform
      when "facebook"
        "Facebook page name"
      when "twitter"
        "Twitter handle"
      when "instagram"
        "Instagram handle"
      when "web"
        "Web URL"

  defaultName: (platform) =>
    platform ?= @model.get("platform")
    switch platform
      when "web"
        "Link label"

  onFocus: (e) =>
    if @ui.name.is(':visible')
      @ui.name.focus()
    else
      @ui.url.focus()
    @model.set 'editing', true

  remove: =>
    @$el.fadeOut 'fast', =>
      @model.destroy()

  addSimilar: =>
    @collection.add
      platform: @_platform

  ifWeb: (platform) =>
    platform is 'web'


# Published view
#
class Cms.Views.SocialLink extends Cms.Views.Social
  template: 'socials/link'
  tagName: "li"

  bindings:
    "a":
      attributes: [
        name: "class",
        observe: "platform"
      ,
        name: "href"
        observe: "normalized_url"
      ]
    "use.platform":
      attributes: [
        name: "xlink:href"
        observe: "platform"
        onGet: "platformSymbol"
      ]
    "span.name":
      observe: ["name", "url"]
      onGet: "thisOrThat"

  onRender: =>
    @stickit()


# EmptyView is an add button.
#
class Cms.Views.AddSocial extends Cms.Views.Social
  template: 'socials/add'
  tagName: "li"
  events:
    "click": "addSocial"

  ui:
    name: "span.name"
    url: "span.url"
    symbol: "use.platform"

  onRender: =>
    # NB no model so nothing to stick to.
    @$el.addClass(@_platform)
    @ui.symbol.attr('href', "##{@_platform}_symbol")
    @ui.name.text @defaultName(@_platform)
    @ui.url.text @defaultUrl(@_platform)

  addSocial: =>
    # cause this view to disappear and a list item to appear ready for editing
    new_social = @_collection.add(platform: @_platform)
    # activate the list item and focus its first visible input
    new_social.trigger 'focus'


class Cms.Views.SocialsManager extends Cms.View
  tagName: "div"
  className: "socials"

  initialize: ->
    @collection = @model.socials
    super

  onRender: =>
    @log "render", @collection
    @collection.loadAnd =>
      for platform in ['twitter', 'facebook', 'instagram', 'web']
        listView = new Cms.Views.SocialsEditList
          collection: @model.socials
          platform: platform
        @$el.append listView.el
        listView.render()


class Cms.Views.SocialsEditList extends Cms.CollectionView
  childView: Cms.Views.Social
  emptyView: Cms.Views.AddSocial
  tagName: "ul"
  className: "socials"

  initialize: (opts={}) ->
    super()
    @_platform = opts.platform
    @viewFilter =
      platform: @_platform

  childViewOptions: (model) =>
    model: model
    platform: @_platform
    collection: @collection


class Cms.Views.SocialsLinkList extends Cms.CollectionView
  childView: Cms.Views.SocialLink
  tagName: "ul"
  className: "links"

  viewFilter: (child) =>
    child.model.get('id') and child.model.get('url')
