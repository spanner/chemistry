class Cms.Views.Social extends Cms.View
  template: 'socials/edit'
  tagName: "li"

  ui:
    prompt: 'span.prompt'
    name: 'span.name'
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
    "a.add":
      observe: "url"
      visible: true

  initialize: (opts={}) ->
    super
    @_platform = opts.platform
    @_collection = opts.collection
    @log "init", @_platform

  onRender: =>
    @model.on 'focus', @onFocus
    @stickit()
    @$el.addClass(@_platform)
    @ui.name.attr "placeholder", @defaultName()

  platformSymbol: (platform) =>
    "##{platform}_symbol"

  defaultName: (platform) =>
    #todo: i18n
    platform ?= @model.get("platform")
    switch platform
      when "facebook"
        "Facebook page name"
      when "twitter"
        "Twitter handle"
      when "instagram"
        "Instagram handle"

  onFocus: (e) =>
    @ui.name.focus()
    @model.set 'editing', true

  remove: =>
    @$el.fadeOut 'fast', =>
      @model.destroy()

  addSimilar: =>
    @collection.add
      platform: @_platform


class Cms.Views.AddSocial extends Cms.Views.Social
  template: 'socials/add'
  tagName: "li"
  events:
    "click": "addSocial"

  ui:
    prompt: "span.name"
    symbol: "use.platform"

  onRender: =>
    @$el.addClass(@_platform)
    @ui.prompt.text @defaultName(@_platform)
    @ui.symbol.attr "xlink:href", @platformSymbol(@_platform)

  addSocial: =>
    new_social = @_collection.add(platform: @_platform)
    new_social.trigger 'focus'


class Cms.Views.SocialsManager extends Cms.CollectionView
  childView: Cms.Views.Social
  emptyView: Cms.Views.AddSocial
  tagName: "span"

  initialize: (opts={}) ->
    super
    @_platform = opts.platform
    @viewFilter =
      platform: @_platform
    @collection.loadAnd =>
      @render()

  childViewOptions: (model) =>
    model: model
    platform: @_platform
    collection: @collection

