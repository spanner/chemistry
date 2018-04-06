class Cms.Views.TermsPicker extends Cms.View
  template: "pick_terms"

  ui:
    keywords: 'input.keywords'

  bindings:
    "input.keywords":
      observe: "keywords"

  onRender: =>
    @initTokenInput()
    @stickit()

  initTokenInput: =>
    if terms = @model.get('keywords')
      existing_terms = _.map _.uniq(terms.split(',')), (t) -> name: t
    else
      existing_terms = []

    url = [_cms.config('api_url'), 'terms'].join('/')
    @ui.keywords.tokenInput url,
      minChars: 2
      tokenValue: "name"
      placeholder: "Keywords"
      prePopulate: existing_terms
      excludeCurrent: true
      allowFreeTagging: true
      hintText: "Type in a search term to see suggestions. Enter creates a new tag."
      onResult: (data) ->
        seen = {}
        terms = []
        data = data.data if data.data
        _.map data, (datum) ->
          term = datum.attributes.term
          unless seen[term]
            terms.push(name: term)
            seen[term] = true
        terms
    @_search_field = @$el.find('li.token-input-input-token input[type="text"]')
    @_search_field.attr "placeholder", @ui.keywords.attr('placeholder')

  focus: =>
    @_search_field?.focus()



# class Cms.Views.TermView extends Cms.CompositeView
#   template: "cms/term"
#   childView: Cms.Views.ListedPageView
#   childViewContainer: "#pages"
#
#   bindings:
#     ".term":
#       observe: "term"
#     "a.close":
#       attributes: [
#         name: 'href'
#         observe: 'id'
#         onGet: "closeHref"
#       ]
#
#   initialize: =>
#     @collection = @model.pages
#     @render()
#
#
# class Cms.Views.ListedTerm extends Cms.View
#   template: "listed_term"
#
#   bindings:
#     "span.term":
#       observe: "term"
#     "a.term":
#       attributes: [
#         name: "href"
#         observe: "term"
#         onGet: "termHref"
#       ]
#
#
# class Cms.Views.AttachedTerms extends Backbone.Marionette.CollectionView
#   childView: Cms.Views.ListedTerm
#   tagName: "ul"
#   className: "terms"
#
#   initialize: ->
#     @collection = new Cms.Collections.Terms
#     @setTerms()
#     @model.on 'change:keywords', @setTerms
#
#   setTerms: =>
#     if keywords = @model.get('keywords')
#       term_data = _.map _.uniq(keywords.split(/,\s*/)), (t) -> term: t
#       @collection.reset term_data
#
#
