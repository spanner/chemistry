# TODO: History of previous paths for redirection
#.      history of edits by users...

require 'mustache'

module Chemistry
  class Page < Chemistry::ApplicationRecord
    PUBLISHED_ATTRIBUTES = [:slug, :path, :title, :masthead, :content, :byline, :summary, :excerpt, :terms, :style, :image_id]

    acts_as_list column: :nav_position

    # Filing
    belongs_to :user, optional: true, class_name: Chemistry.config.user_class, foreign_key: Chemistry.config.user_key
    belongs_to :page_collection, optional: true
    belongs_to :page_category, optional: true 

    # Tree-building
    belongs_to :parent, class_name: 'Chemistry::Page', optional: true
    has_many :child_pages, class_name: 'Chemistry::Page', foreign_key: :parent_id, dependent: :destroy

    # first masthead image is extracted for display in lists
    belongs_to :image, class_name: 'Chemistry::Image', optional: true
    belongs_to :published_image, class_name: 'Chemistry::Image', optional: true

    before_validation :set_home_if_first
    before_validation :derive_slug_and_path
    before_validation :set_default_style

    validates :title, presence: true
    # validate :has_path_and_slug

    attr_accessor :publishing
    validates :published_path, uniqueness: true, if: :publishing?
    validates :published_content, presence: true, if: :publishing?

    scope :home, -> { where(home: true).limit(1) }
    scope :nav, -> { where(nav: true) }
    scope :published, -> { where.not(published_at: nil) }
    scope :featured, -> { where.not(featured_at: nil).order(featured_at: :desc) }
    scope :uncollected, -> { where(page_collection_id: nil) }
    scope :uncategorised, -> { where(page_category_id: nil) }
    scope :latest, -> { order(created_at: :desc) }
    scope :with_parent, -> page { where(parent_id: page.id) }
    scope :with_path, -> path { where(path: path) }
    scope :at_or_below, -> path { where("path like ?", "#{path}%")}

    class << self
      def for_selection(page_collection=nil, except_page=nil)
        if page_collection
          pages = page_collection.pages
        else
          pages = uncollected
        end
        if except_page
          pages = pages.other_than(except_page)
        end
        pages.order(:title).map{|page| [page.title, page.id] }
      end

      def tree_for_selection(page_collection=nil, except_page=nil)
        if page_collection
          pages = page_collection.pages
        else
          pages = uncollected
          root = home_page
        end
        if except_page
          pages = pages.other_than(except_page)
        end
        index = pages.each_with_object({}) do |p, h|
          key = p.parent_id.presence || '__root'
          h[key] ||= []
          h[key].push(p)
        end
        branch_for_selection(root, index)
      end

      def branch_for_selection(page, index, depth=0, seen={})
        branch = []
        if (page)
          unless seen[page.id]
            seen[page.id] = true
            branch.push branch_page_option(page, depth)
            children = index[page.id]
            depth += 1
          end
        else
          unless seen['__root']
            seen['__root'] = true
            children = index['__root']
          end
        end
        if children && children.any?
          children.each do |child|
            branch.concat branch_for_selection(child, index, depth, seen)
          end
        end
        branch
      end

      def branch_page_option(page, depth)
        prefix = "&nbsp;" * depth * 4
        label = (prefix + page.title).html_safe
        [label, page.id]
      end

      def home_page
        home.first
      end

      def published_with_path(path)
        where(published_path: path).where.not(published_at: nil).first
      end

      def page_tree(root=nil)
        if root
          pages = at_or_below(root.path)
        else
          pages = uncollected
          root = home_page
        end
        index = pages.each_with_object({}) do |p, h|
          h[p.parent_id] ||= []
          h[p.parent_id].push(p)
        end
        branch_from(root, index)
      end

      def branch_from(page, index, depth=0, seen={})
        seen[page.id] = true
        branch = {
          p: page,
          d: depth
        }
        if index[page.id]
          children = []
          children_in_order = index[page.id].sort_by { |p| p.title.presence || 'zzz' }
          children_in_order.each do |child|
            unless seen[child.id]
              children.push branch_from(child, index, depth + 1, seen)
            end
            branch[:c] = children
          end
        end
        branch
      end
    end

    def published?
      published_at?
    end

    def amended?
      updated_at && (updated_at > created_at)
    end

    def publishing?
      !!publishing
    end

    # Featuredness is held as date of featuring but usually passed around as a boolean `featured` property.
    #
    def featured?
      featured_at?
    end

    def featured
      featured_at?
    end

    def featured=(value)
      if value == true || value == 'true' || value == 1
        self.featured_at = Time.now
      elsif value == false || value == 'false' || value == 0
        self.featured_at = nil
      end
    end

    def public?
      !private?
    end

    def publish!
      transaction do
        PUBLISHED_ATTRIBUTES.each do |col|
          self.send("published_#{col}=".to_sym, self.send(col.to_sym))
        end
        self.published_at = Time.now + 2.seconds    # hack to ensure > updated_at
        self.publishing = true                      # engage validations
        if valid?
          self.save!
          return true
        else
          return false
        end
      end
    rescue => e
      Rails.logger.warn("⚠️ Publication fail", e.message);
      return false
    end


    ## Interpolations
    # override to provide site-wide interpolations available on any page.
    # They can be string-like: {{published_at}} returns a formatted datetime.
    # or proc-like: {{login_form}} could render a template partial with this as `page` argument.
    # Rendered partials should only refer to page properties since they are rendered before publication.
    # Anything user-specific must be added post-cache by fetching a partial after browwser loads page.
    #
    def interpolations
      {
        published_at: I18n.l(published_at, format: :natural),
        byline: byline.presence || ""
      }.merge(custom_interpolations)
    end

    def custom_interpolations
      {}
    end


    # Render performs the interpolations by passing our attributes (usually blocks of html) and interpolation rules to mustache.
    #
    def render(attribute=:published_content)
      content = read_attribute(attribute)
      if content.present? 
        if interpolable_attributes.include?(attribute)
          Mustache.render(content, interpolations)
        else
          content
        end
      else
        ""
      end
    end


    ## Elasticsearch indexing
    #
    searchkick searchable: [:path, :working_title, :title, :content, :byline],
               word_start: [:title],
               highlight: [:title, :content]

    scope :search_import, -> { includes(:image, :page_collection, :page_category) }

    def search_data
      fields = {
        # chiefly for UI retrieval
        slug: published_slug.presence || slug,
        path: published_path.presence || path,
        style: published_style.presence || style,
        title: strip_tags(published_title.presence || title),

        # public archive / search
        home: home?,
        masthead: strip_tags(published_masthead.presence || masthead),
        content: strip_tags(published_content.presence || content),
        byline: strip_tags(published_byline.presence || byline),
        summary: strip_tags(published_summary.presence || summary),
        excerpt: strip_tags(published_excerpt.presence || excerpt),
        terms: terms_list,
        image_url: image_url,
        thumbnail_url: thumbnail_url,
        page_collection_name: page_collection_name,
        page_category_name: page_category_name,

        # aggregation and selection
        parent_id: parent_id,
        page_collection: page_collection_slug,
        page_collection_id: page_collection_id,
        page_category: page_category_slug,
        page_category_id: page_category_id,
        created_at: created_at,
        updated_at: updated_at,
        published: published?,
        published_at: published_at,
        searchable: searchable?,
        collection_featured: page_collection_featured?,
        featured: featured?,
        featured_at: featured_at,
        date: featured_at.presence || published_at.presence || created_at,
        year: year,
        month: month_and_year
      }
      fields.merge(extra_search_data)
    end

    def extra_search_data
      {}
    end

    # Search and aggregation
    # Here we support the public archive and admin interfaces with faceting and date-filtering controls.
    # There is also a simpler filter-and-paginate search in the Pages API.

    def self.search_and_aggregate(params={})
      Rails.logger.warn "🌸 Page.search_and_aggregate #{params.inspect}"

      # search
      #
      fields = ['title^5', 'path^2', 'summary^3', 'content', 'byline']
      highlight = {tag: "<strong>", fields: {title: {fragment_size: 40}, content: {fragment_size: 320}}}

      if params[:q].present?
        terms = params[:q]
        default_order = {_score: :desc}
      else
        terms = "*"
        default_order = {created_at: :desc}
      end

      # filter
      #
      criteria = { published: true, searchable: true }
      criteria[:page_collection] = params[:page_collection] if params[:page_collection].present?
      criteria[:page_category] = params[:page_category] if params[:page_category].present?
      criteria[:terms] = params[:terms] if params[:term].present?

      if params[:date_from].present? or params[:date_to].present?
        criteria[:date] = {}
        criteria[:date][:gt] = Date.parse(params[:date_from]).beginning_of_day if params[:date_from].present?
        criteria[:date][:lte] = Date.parse(params[:date_to]).end_of_day if params[:date_to].present?
      elsif params[:month].present? and params[:year].present?
        criteria[:month] = [params[:year], params[:month]].join('/')
      end

      # sort
      #
      if params[:sort].present?
        if params[:order].present?
          order = {params[:sort] => params[:order]}
        elsif %w{created_at featured_at published_at}.include?(params[:sort])
          order = {params[:sort] => :desc}
        else
          order = {params[:sort] => :asc}
        end
      elsif params[:order].present?
        order = {published_at: params[:order]}
      else
        order = default_order
      end

      # paginate
      #
      per_page = (params[:show].presence || 20).to_i
      page = (params[:page].presence || 1).to_i

      # aggregate
      #
      aggregations = {
        month: {},
        year: {},
        page_category: {},
        page_collection: {},
      }

      body_options = {
        aggs: {
          date_stats: { "stats": { "field": "date" } }
        }
      }

      options = {
        load: false,
        fields: fields,
        where: criteria,
        order: order,
        per_page: per_page,
        page: page,
        highlight: highlight,
        aggs: aggregations,
        body_options: body_options
      }
      Rails.logger.warn "🌸 search options: #{terms}, #{options.inspect}"

      # fetch
      #
      Page.search terms, options
    end

    def similar_pages
      if tokens = terms_list
        Chemistry::Page.search(body: {query: {match: {terms: tokens}}}, limit: 19);
      else
        []
      end
    end

    def section_head?
      parent && parent.home?
    end

    # Indexing support

    def render_and_strip_tags(attribute=:published_content)
      strip_tags(render(attribute))
    end

    def strip_tags(html)
      if html.present?
        ActionController::Base.helpers.strip_tags(html)
      else
        ""
      end
    end

    def terms_list
      list_of(published_terms.presence || terms)
    end

    def list_of(terms)
      if terms.present?
        terms.split(',').compact.uniq
      else
        []
      end
    end

    def image_url
      if published_image
        published_image.file_url(:full)
      elsif image
        image.file_url(:full)
      end
    end

    def thumbnail_url
      if published_image
        published_image.file_url(:thumb)
      elsif image
        image.file_url(:thumb)
      end
    end

    def page_collection_name
      page_collection.short_title if page_collection
    end

    def page_collection_slug
      page_collection.slug if page_collection
    end

    def page_collection_featured?
      page_collection.featured? if page_collection
    end

    def page_category_name
      page_category.title if page_category
    end

    def page_category_slug
      page_category.slug if page_category
    end

    def year
      if published_at.present?
        published_at.strftime("%y")
      end
    end

    def month_and_year
      if published_at.present?
        published_at.strftime("%y/%m")
      end
    end

    def searchable?
      !page_collection || page_collection.searchable?
    end


    # Paths

    def absolute_path
      if page_collection
        tidy_slashes ["", page_collection.path.presence, path.presence].compact.join('/')
      elsif home?
        ""
      else
        tidy_slashes(path)
      end
    end

    def slug_base
      if home?
        ""
      else
        base = published_title.presence || title.presence || "Untitled page"
        base.parameterize
      end
    end

    def path_base
      path_parts = []
      path_parts.push page_collection.slug if page_collection
      path_parts.push parent.path if parent && !parent.home?
      tidy_slashes(path_parts.compact.join('/'))
    end

    def tidy_slashes(string)
      string.sub(/\/$/, '').sub(/^\//, '').sub(/^\/{2,}/, '/');
    end


    protected

    def interpolable_attributes
      [:published_masthead, :published_content, :published_byline, :published_excerpt]
    end

    # During creation, first page in a site or collection is automatically marked as 'home'.
    def set_home_if_first
      if Page.all.empty?
        self.home = true
      elsif page_collection && page_collection.empty?
        self.home = true
      end
    end

    def set_default_style
      self.style ||= Chemistry.config.default_page_style
    end

    # Path is absolute and includes collection prefix so that we can match fast and route simply
    #
    def derive_slug_and_path
      if home?
        self.slug = ""
      elsif slug? && !persisted?
        self.slug = add_suffix_if_taken(slug, path_base)
      elsif !slug?
        self.slug = add_suffix_if_taken(slug_base, path_base)
      end
      self.path = tidy_slashes([path_base, slug].map(&:presence).compact.join("/"))
    end

    def add_suffix_if_taken(base, scope_path)
      slug = base
      addendum = 1
      while Chemistry::Page.find_by(path: [scope_path, slug].join('/'))
        slug = base + '-' + addendum.to_s
        addendum += 1
      end
      slug
    end

    def has_path_and_slug
      slug_valid = slug.present? || (home? && slug == "")
      path_valid = path.present? || (home? && path == "")
      path_unique = has_unique_path
      slug_valid && path_valid && path_unique
    end

    def has_unique_path
      !Chemistry::Page.other_than(self).find_by(path: path)
    end

  end
end