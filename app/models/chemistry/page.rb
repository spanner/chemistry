require 'mustache'

module Chemistry
  class Page < Chemistry::ApplicationRecord
    acts_as_list column: :nav_position

    # Filing
    belongs_to :page_collection, optional: true
    belongs_to :page_category, optional: true 

    # Tree-building
    belongs_to :parent, class_name: 'Chemistry::Page', optional: true
    has_many :child_pages, class_name: 'Chemistry::Page', foreign_key: :parent_id, dependent: :destroy

    # Links
    has_many :socials, class_name: 'Chemistry::Social', dependent: :destroy
    accepts_collected_attributes_for :socials

    #TODO remove after migration
    # `terms` is now an ad-hoc list in text
    has_many :page_terms
    has_many :old_terms, through: :page_terms, class_name: "Chemistry::Term"

    # first masthead image is extracted for display in lists
    belongs_to :image, optional: true

    before_validation :set_home_if_first
    before_validation :derive_slug_and_path

    validates :title, presence: true
    validates :slug, presence: true, uniqueness: {scope: :parent_id}
    validates :path, presence: true, uniqueness: true

    attr_accessor :publishing
    validates :published_path, presence: true, uniqueness: true, if: :publishing?
    validates :published_content, presence: true, if: :publishing?

    scope :home, -> { where(home: true).limit(1) }
    scope :nav, -> { where(nav: true) }
    scope :published, -> { where.not(published_at: nil) }
    scope :latest, -> { order(created_at: :desc) }
    scope :with_parent, -> page { where(parent_id: page.id) }
    scope :with_path, -> path { where(path: path) }

    def self.published_with_path(path)
      where(published_path: path).where.not(published_at: nil).first
    end

    def published?
      published_at?
    end

    def publishing?
      !!publishing
    end

    def featured?
      featured_at?
    end

    def public?
      !private?
    end

    def absolute_path
      #TODO: mount point, by way of public_page_url(page)?
      "/" + path
    end

    def publish!
      transaction do
        %w{slug path title masthead content byline summary excerpt terms style}.each do |col|
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
    # They can be string like {{user_count}} or proc like {{login_form}}.
    #
    def interpolations
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

    def search_data
      {
        # chiefly for UI retrieval
        slug: published_slug.presence || slug,
        path: published_path.presence || path,
        style: published_style.presence || style,
        title: strip_tags(published_title.presence || title),

        # public archive / search
        masthead: strip_tags(published_masthead.presence || masthead),
        content: strip_tags(published_content.presence || content),
        byline: strip_tags(published_byline.presence || byline),
        summary: strip_tags(published_summary.presence || summary),
        excerpt: strip_tags(published_excerpt.presence || excerpt),
        terms: terms_list(published_terms.presence || terms),

        # aggregation and selection
        parent: parent_id,
        page_collection: page_collection_id,
        page_category: page_category_id,
        created_at: created_at,
        updated_at: updated_at,
        published: published?,
        published_at: published_at,
        featured: featured?,
        featured_at: featured_at,
        date: featured_at.presence || published_at.presence || created_at
      }
    end

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

    def terms_list(terms)
      if terms.present?
        terms.split(',').compact.uniq
      else
        []
      end
    end

    def similar_pages
      if tokens = terms_list(published_terms);
        Chemistry::Page.search(body: {query: {match: {terms: tokens}}}, limit: 19);
      else
        []
      end
    end

    def slug_base
      published_title.presence || title
    end

    def path_base
      if parent && parent.path?
        tidy_slashes(parent.path)
      elsif page_collection
        page_collection.slug
      else
        ""
      end
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

    # Path is absolute and includes collection prefix so that we can match fast and route simply
    #
    def derive_slug_and_path
      if home?
        self.slug = "__home"
        self.path = [path_base, 'home'].join("/")
      else
        if slug? && !persisted?
          self.slug = add_suffix_if_taken(slug, path_base)
        elsif !slug?
          self.slug = add_suffix_if_taken(slug_base, path_base)
        end
        self.path = [path_base, slug].join("/")
      end
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

  end
end