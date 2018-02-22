class Cms.Models.Template extends Cms.Model
  savedAttributes: ['title', 'description']
  savedAssociations: ['placeholders']

  build: =>
    @hasMany 'placeholders'
