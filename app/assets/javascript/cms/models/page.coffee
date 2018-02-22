class Cms.Models.Page extends Cms.Model
  savedAttributes: ['template_id', 'parent_id', 'slug', 'title', 'slug', 'summary', 'home', 'nav', 'nav_name', 'nav_position']
  savedAssociations: ['sections']

  defaults:
    nav: false
    home: false

  build: =>
    @belongsTo 'template'
    @hasMany 'sections'

  published: () =>
    @get('published_at')?
  
  # Publish is a special save that sends up our rendered html for composition and saving.
  #
  publish: () =>
    $.ajax
      url: @url() + "/publish"
      data:
        rendered_html: @render()
      method: "PUT"
      success: @published
      error: @failedToPublish
  
  published: (response) =>
    @set(response)

  failedToPublish: (request) =>
    #...

  render: () =>
    renderer = new Cms.Views.PageRenderer
      model: @
      collection: @sections
    renderer.render()
    renderer.el.innerHTML
