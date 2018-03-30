class Cms.Models.Template extends Cms.Model
  savedAttributes: ['title', 'slug', 'description', 'position']
  savedAssociations: ['placeholders']

  build: =>
    @hasMany 'placeholders'


class Cms.Collections.Templates extends Cms.Collection
  model: Cms.Models.Template
  paginated: false
