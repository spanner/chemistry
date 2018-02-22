class Cms.Collections.SectionTypes extends Cms.Collection
  model: Cms.Models.SectionType

  # initialize: ->
  #   section_types =
  #     default: 'Long text'
  #     onecol: "One column"
  #     twocol: "Two columns"
  #     asideimage: "Text & picture"
  #     bigpicture: "Big picture"
  #     asidequote: "Text and quote"
  #     bigquote: "Big quote"
  #     hero: "Hero"
  #     gallery: "Gallery"
  #     contents: "Contents"
  #     links: "Link blocks"
  #     enquiry: "Contact form"
  #
  #   for slug, name of section_types
  #     @add
  #       name: name
  #       slug: slug
