# class Cms.Views.TermView extends Cms.CollectionView
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
# class Cms.Views.AttachedTerms extends Marionette.CollectionView
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
