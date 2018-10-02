class Cms.Models.Page extends Cms.Model
  savedAttributes: ['template_id', 'parent_id', 'slug', 'title', 'slug', 'content', 'summary', 'external_url', 'document_id', 'keywords', 'home', 'nav', 'nav_name', 'nav_position', 'date', 'to_date', 'rendered_html', 'image_id']
  savedAssociations: ['sections']

  defaults:
    nav: false
    home: false
    parental: false
    collapsed: false     # my children are hidden in tree
    concealed: false        # I am hidden in tree
    content: 'page'

  build: =>
    @belongsTo 'template'
    @belongsTo 'parent'
    @hasMany 'sections'
    @setPublicationStatus()
    @on 'change:updated_at change:published_at', @setPublicationStatus
    @on 'change:rendered_html', @extractMetadata
    @on 'change:title', @setSlug

  published: () =>
    @get('published_at')?

  # Publish is just a save that sends up our rendered html.
  #
  render: =>
    @_renderer ?= new Cms.Views.PageRenderer 
      model: @
    @_renderer.render() # sets our `rendered_html`, `excerpt` and `image`

  publish: () =>
    @render()
    @save().done(@publishSucceeded).fail(@publishFailed)

  publishSucceeded: (response) =>
    attrs = @parse response
    @set attrs
    @confirm t('reassurances.page_published')

  publishFailed: (request) =>
    @complain("Error #{request.status}: #{request.responseText}")

  setPublicationStatus: =>
    if !@get('published_at')
      @set 'unpublished', true
      @set 'outofdate', false
    else
      @set 'unpublished', false
      @set 'outofdate', @get('updated_at') > @get('published_at')

  revert: =>
    @reload()
    @sections.reload()

  confirmSave: =>
    @confirm t('reassurances.page_saved')

  setSlug: =>
    new_title = @get('title')
    previous_title = @previous('title')
    previous_slug = @get('slug')
    if !previous_slug or previous_slug is @slugify(previous_title)
      @set 'slug', @slugify(new_title)

  slugify: (title) =>
    title.toString().toLowerCase()
      .replace('&nbsp;', ' ')
      .replace(/[åàáãäâ]/, 'a')
      .replace(/[èéëê]/, 'e')
      .replace(/[ìíïî]/, 'i')
      .replace(/[òóöô]/, 'o')
      .replace(/[ùúüû]/, 'u')
      .replace(/ñ/, 'n')
      .replace(/ç/, 'c')
      .replace(/ß/, 'ss')
      .replace(/\s+/g, '-')           # Replace spaces with -
      .replace(/[^\w\-]+/g, '')       # Remove all non-word chars
      .replace(/\-\-+/g, '-')         # Replace multiple - with single -
      .replace(/^-+/, '')             # Trim - from start of text
      .replace(/-+$/, '')             # Trim - from end of text
      .trim()


  extractMetadata: =>
    html = @get('rendered_html')
    title = ""
    excerpt = ""
    image_id = null
    video_id = null
    $holder = $('<div />')
    $holder.html(html)

    # retrieve page title as edited
    $heading = $holder.find('h1')
    if $heading.length
      title = $heading.first().text()
      $heading.remove()
    @set('title', title) if title

    # extract a bit of text from first content section
    $main_section = $holder.find('section.standfirst, section.standard')
    if $main_section.length
      excerpt = $main_section.text().split(/\s+/).slice(0,64).join(' ')
    else
      excerpt = $holder.text().split(/\s+/).slice(0,64).join(' ')
    @set('excerpt', excerpt) if excerpt

    # grab image id from first image asset block (heroic or embedded)
    $image_headers = $holder.find('[data-asset-type="image"]')
    if $image_headers.length
      image_id = $image_headers.first().attr('data-asset-id')
    unless image_id
      $image_blocks = $holder.find('[data-image]')
      if $image_blocks.length
        image_id = $image_blocks.first().attr('data-image')
    @set('image_id', image_id) if image_id

    # grab video id from first video asset block (heroic or embedded)
    $video_headers = $holder.find('[data-asset-type="video"]')
    if $video_headers.length
      video_id = $video_headers.first().attr('data-asset-id')
    unless video_id
      $video_blocks = $holder.find('[data-video]')
      if $video_blocks.length
        video_id = $video_blocks.first().attr('data-video')
    @set('video_id', video_id) if video_id

  children: =>
    @collection.where(parent_id: @id)

  getChildren: =>
    new Cms.Collections.Pages @children()

  #TODO stash this locally for resumption.
  toggleChildren: =>
    if @get('collapsed')
      @revealChildren()
      @set 'collapsed', false
    else
      @concealChildren()
      @set 'collapsed', true

  revealChildren: =>
    @children().forEach (p) -> p.reveal()

  concealChildren: =>
    @children().forEach (p) -> p.conceal()

  reveal: =>
    @log "reveal"
    @set 'concealed', false, stickitChange: true
    @revealChildren() unless @get('collapsed')

  conceal: =>
    @log "conceal"
    @set 'concealed', true, stickitChange: true
    @concealChildren()


class Cms.Collections.Pages extends Cms.Collection
  model: Cms.Models.Page
  comparator: "position"

  initialize: =>
    super
    _.defer =>
      @buildTree()
      @on 'add remove reset change:parent_id', _.debounce @buildTree, 100

  rootPage: =>
    @findWhere home: true

  ## Page tree
  # This is only for display purposes and there is no need to maintain parent/child relations.
  # For each page we only need to
  # set overall position
  # set depth in tree
  # note parenting status
  # and depth would be nice
  #
  buildTree: =>
    parentage = {}
    @forEach (m) ->
      m.set parental: false
    @each (model) =>
      if parent = model.get('parent')
        parent.set parental: true
      key = model.get('parent_id') or "none"
      parentage[key] ?= []
      parentage[key].push model
    if root = parentage['none']?[0]
      pos = 0
      depth = 0
      final_pos = @buildBranch root, pos, depth, parentage
    @sort()

  # walk tree to set depth and position of each page
  #
  buildBranch: (stem, pos, depth, parentage) =>
    stem.set
      depth: depth
      position: pos
    if parentage[stem.id]
      _.each parentage[stem.id], (child) =>
        pos = @buildBranch child, pos + 1, depth + 1, parentage
    pos
