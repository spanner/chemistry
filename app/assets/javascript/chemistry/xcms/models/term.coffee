class Cms.Models.Term extends Cms.Model
  build: =>
    @hasMany 'pages'


class Cms.Collections.Terms extends Cms.Collection
  model: Cms.Models.Term
