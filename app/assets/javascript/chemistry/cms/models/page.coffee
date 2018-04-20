class Cms.Models.Page extends Cms.Model
  savedAttributes: ['template_id', 'parent_id', 'slug', 'title', 'slug', 'content', 'summary', 'external_url', 'document_id', 'keywords', 'home', 'nav', 'nav_name', 'nav_position', 'began_at', 'ended_at']
  savedAssociations: ['sections']

  defaults:
    nav: false
    home: false
    content: 'page'

  build: =>
    @belongsTo 'template'
    @belongsTo 'parent'
    @hasMany 'sections'
    @setPublicationStatus()
    @on 'change:updated_at change:published_at', @setPublicationStatus

  published: () =>
    @get('published_at')?

  # Publish is a special save that sends up our rendered html for composition and saving.
  #
  render: =>
    @_renderer ?= new Cms.Views.PageRenderer 
      model: @
    @_renderer.render()

  publish: () =>
    @render()
    @save()
    $.ajax
      url: @url() + "/publish"
      data:
        rendered_html: @get('rendered_html')
      method: "PUT"
      success: @published
      error: @failedToPublish

  published: (response) =>
    attrs = @parse response
    @set attrs

  failedToPublish: (request) =>
    #...
    debugger

  setPublicationStatus: =>
    @set 'unpublished', !@get('published_at') or @get('updated_at') > @get('published_at')

  revert: =>
    @reload()
    @sections.reload()



class Cms.Collections.Pages extends Cms.Collection
  model: Cms.Models.Page
  comparator: "position"

  initialize: =>
    super
    _.defer =>
      @buildTree()
      @on 'add remove reset change:parent_id', _.debounce @buildTree, 100

  ## Page tree
  # This is only for display purposes and there is no need to maintains parent/child relations.
  # For each page we only need to
  # set overall position
  # set depth in tree
  #
  buildTree: =>
    @log "buildTree", @size()
    parentage = {}
    @each (model) =>
      key = model.get('parent_id') or "none"
      parentage[key] ?= []
      parentage[key].push model
    if root = parentage['none']?[0]
      pos = 0
      depth = 0
      final_pos = @buildBranch root, pos, depth, parentage
    @sort()

  buildBranch: (stem, pos, depth, parentage) =>
    stem.set
      depth: depth
      position: pos
    if parentage[stem.id]
      _.each parentage[stem.id], (child) =>
        pos = @buildBranch child, pos + 1, depth + 1, parentage
    pos