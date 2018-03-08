class Cms.Models.Template extends Cms.Model
  savedAttributes: ['title', 'slug', 'description', 'position']
  savedAssociations: ['placeholders']

  build: =>
    @hasMany 'placeholders'
