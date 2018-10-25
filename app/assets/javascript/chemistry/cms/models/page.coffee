class Cms.Models.Page extends Cms.Model
  savedAttributes: ['template_id', 'parent_id', 'slug', 'title', 'slug', 'content', 'summary', 'excerpt', 'external_url', 'document_id', 'keywords', 'home', 'nav', 'nav_name', 'nav_position', 'date', 'to_date', 'rendered_html', 'image_id']
  savedAssociations: ['sections', 'socials']

  defaults:
    nav: false
    home: false
    parental: false
    collapsed: false        # my children are hidden in tree
    concealed: false        # I am hidden in tree
    content: 'page'

  build: =>
    @belongsTo 'template'
    @belongsTo 'parent'
    @hasMany 'socials'
    @hasMany 'sections'
    @sections.on 'add remove reset change:primary_html change:secondary_html', @checkPopulatedness              # don't set on load: is passed down

    @setPublicationStatus()
    @on 'change:updated_at change:published_at', @setPublicationStatus
    @on 'change:rendered_html', @extractMetadata
    @on 'change:title', @setSlug
    @on 'change:collapsed', @storeDisplayState
    @on 'change:template_has_changed', @reloadSectionsIfTemplateChanged

  published: () =>
    !@get('unpublished')

  # The basic rule here is that work in progress is stord in composable section attributes while the published page is stored in a single rendered block.
  # `Publish` is just a save that assembles, cleans and sends up the rendered html.
  #
  publish: () =>
    @render()
    @save().done(@publishSucceeded).fail(@publishFailed)

  render: =>
    @_renderer ?= new Cms.Views.PageRenderer 
      model: @
    @_renderer.render()
    @set 'rendered_html', @_renderer.getRenderedHtml()

  publishSucceeded: (response) =>
    attrs = @parse response
    @set attrs
    @confirm t('reassurances.page_published')

  publishFailed: (request) =>
    @complain("Error #{request.status}: #{request.responseText}")

  setPublicationStatus: =>
    if !@get('published_at')
      @set 'unpublished', true
      @set 'outofdate', true
    else
      @set 'unpublished', false
      @set 'outofdate', @get('updated_at') > @get('published_at')

  checkPopulatedness: =>
    populated = @sections.some (s) =>
      s.get("primary_html") or s.get("secondary_html")
    @set 'empty', !populated

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
      .replace('&nbsp;', ' ')         # remove contenteditable space-holders
      .replace(/[åàáãäâ]/, 'a')       #
      .replace(/[èéëê]/, 'e')         #
      .replace(/[ìíïî]/, 'i')         #
      .replace(/[òóöô]/, 'o')         # flatten accented characters
      .replace(/[ùúüû]/, 'u')         #
      .replace(/ñ/, 'n')              #
      .replace(/ç/, 'c')              #
      .replace(/ß/, 'ss')             #
      .replace(/\s+/g, '-')           # Replace spaces with -
      .replace(/[^\w\-]+/g, '')       # Remove all non-word chars
      .replace(/\-\-+/g, '-')         # Replace multiple - with single -
      .replace(/^-+/, '')             # Trim - from start of text
      .replace(/-+$/, '')             # Trim - from end of text
      .trim()                         # Remove leading and trailing spaces

  extractMetadata: =>
    @log "extractMetadata"
    html = @get('rendered_html')
    title = ""
    excerpt = ""
    image_id = null
    video_id = null
    $holder = $('<div />')
    $holder.html(html)

    # retrieve page title and prefix that were previously given to the first section and may have been edited since.
    # NB this restates bindings in a way that is meant to be general, but should we side-effect it during render or update instead?
    #
    heading = $holder.find('h1')
    if heading.length
      prefix_span = heading.find('span.prefix')
      if prefix_span.length
        prefix = prefix_span.first().text()
      title_span = heading.find('span.title')
      if title_span.length
        title = title_span.first().text()
      else
        title = heading.first().text()
      heading.remove()
    @set('prefix', prefix) if prefix
    @set('title', title) if title

    # extract a bit of text from first content section
    $content_sections = $holder.find('section.standfirst, section.standard')
    excerpt = $content_sections.text().split(/\s+/).slice(0,64).join(' ')
    @set('excerpt', excerpt)
    @log "-> excerpt", excerpt

    # grab image id from first image asset block of any kind
    # heroic...
    $image_headers = $holder.find('[data-asset-type="image"]')
    if $image_headers.length
      image_id = $image_headers.first().attr('data-asset-id')
    unless image_id
      # or embedded
      $image_blocks = $holder.find('[data-image]')
      if $image_blocks.length
        image_id = $image_blocks.first().attr('data-image')
    @set('image_id', image_id) if image_id

    # grab video id from first video asset block (also could be heroic or embedded)
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

  # a collapsed item remains visible in the tree but its children are concealed.
  #
  toggleCollapse: =>
    if @get('collapsed') then @uncollapse() else @collapse()

  collapse: =>
    @concealChildren()
    @set 'collapsed', true

  uncollapse: =>
    @revealChildren()
    @set 'collapsed', false

  concealChildren: =>
    @children().forEach (p) -> p.conceal()

  revealChildren: =>
    @children().forEach (p) -> p.reveal()

  # a concealed item is hidden in the tree
  #
  conceal: =>
    @set 'concealed', true, stickitChange: true
    @concealChildren()

  reveal: =>
    @set 'concealed', false, stickitChange: true
    @revealChildren() unless @get('collapsed')

  # called on change:collapsed to persist tree state in this browser.
  # stored values are read directly by the page tree view so that tree state can be restored in a single pass.
  #
  storeDisplayState: =>
    collapses = localStorage.getItem('collapsed_pages')?.split(',') || []
    page_id = @id.toString()
    if @get('collapsed')
      collapses.push page_id
    else
      collapses = _.without(collapses, page_id)
    localStorage.setItem 'collapsed_pages', _.compact(_.uniq(collapses)).join(',')

  reloadSectionsIfTemplateChanged: =>
    if @get('template_has_changed')
      @sections.reload()
      @unset 'template_has_changed', silent: true


class Cms.Collections.Pages extends Cms.Collection
  model: Cms.Models.Page
  comparator: "position"

  initialize: =>
    super
    treeMaintenance = _.debounce @buildTree, 100, true
    @on 'add remove reset change:parent_id', treeMaintenance
    treeMaintenance()

  rootPage: =>
    @findWhere home: true


  ## Page tree
  # This is only for display purposes and there is no need to maintain parent/child relations.
  # For each page we only need to
  # set overall position
  # set depth in tree
  # note parenting status and depth
  #
  buildTree: =>
    @log "buildTree"
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
      children = _.sortBy parentage[stem.id], (p) -> p.get('title')
      _.each children, (child) =>
        pos = @buildBranch child, pos + 1, depth + 1, parentage
    pos
