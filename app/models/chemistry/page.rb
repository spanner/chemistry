require 'mustache'

module Chemistry
  class Page < Chemistry::ApplicationRecord
    acts_as_paranoid
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
    # terms is now an ad-hoc list in text
    has_many :page_terms
    has_many :old_terms, through: :page_terms, class_name: "Chemistry::Term"

    # first masthead image is extracted for display in lists
    belongs_to :image, optional: true

    before_validation :derive_slug_and_path
    before_validation :set_home_if_first

    validates :title, presence: true
    validates :path, uniqueness: {conditions: -> { where(deleted_at: nil) }}

    before_update :note_publication_date

    scope :home, -> { where(home: true).limit(1) }
    scope :nav, -> { where(nav: true) }
    scope :undeleted, -> { where(deleted_at: nil) }
    scope :published, -> { undeleted.where.not(published_at: nil) }
    scope :placeholders, -> { where(role: 'empty') }
    scope :published_and_placeholders, -> { published.or(placeholders) }
    scope :latest, -> { order(created_at: :desc) }
    scope :with_parent, -> page { where(parent_id: page.id) }
    scope :with_path, -> path { where(path: path) }


    def self.published_page_at(path)
      where(path: path).where.not(published_at: nil).first
    end

    def published?
      published_at?
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


    ## Interpolations
    # override to provide site-wide interpolations available on any page.
    # They can be string like {{user_count}} or proc like {{login_form}}.
    #
    def interpolations
      {}
    end


    # Render performs the interpolations by passing our attributes (usually blocks of html) and interpolation rules to mustache.
    #
    def render(attribute=:published_html)
      if interpolable_attributes.include? attribute
        Mustache.render(read_attribute(attribute), interpolations)
      else
        ""
      end
    end


    ## Elasticsearch indexing
    #
    searchkick searchable: [:title, :content],
               word_start: [:title],
               highlight: [:title, :content]

    def search_data
      {
        path: path,
        title: published_title.presence || title,
        content: clean_published_html,
        terms: terms_list,
        page_style: style,
        page_collection: page_collection_id,
        page_category: page_category_id,
        published: published?,
        published_at: published_at,
        featured: featured?,
        featured_at: featured_at
      }
    end

    def clean_published_html
      ActionController::Base.helpers.strip_tags(published_html)
    end

    def terms_list
      if terms?
        terms.split(',').compact.uniq
      else
        []
      end
    end

    def slug_base
      published_title.presence || title
    end

    # Pages are routed 
    #
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
      [:published_title, :published_html, :published_byeline, :published_excerpt]
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
        if !slug? 
          self.slug = add_suffix_if_taken(slug_base, path_base)
        end
        self.path = [path_base, slug].join("/")
      end
    end

    def add_suffix_if_taken(base, scope_path)
      slug = base
      addendum = 1
      while Chemistry::Page.find_by(path: [scope_path, slug].join('/'))
        slug = base + '_' + addendum.to_s
        addendum += 1
      end
      slug
    end

    # tiny little bodge here to make sure that published_at ends up being later than updated_at.
    def note_publication_date
      if will_save_change_to_published_html?
        self.published_at = Time.now + 2.seconds 
      end
    end

  end
end