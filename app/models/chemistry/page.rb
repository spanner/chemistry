require 'mustache'

module Chemistry
  class Page < Chemistry::ApplicationRecord
    acts_as_paranoid
    acts_as_list column: :nav_position

    # minimal tree-building
    belongs_to :parent, class_name: 'Chemistry::Page', optional: true
    has_many :child_pages, class_name: 'Chemistry::Page', foreign_key: :parent_id, dependent: :destroy

    # things in main_app can `have_page` throught the :owner association
    belongs_to :owner, polymorphic: true, optional: true

    # and the association can declare a position in the page tree, such that eg. all event pages are under /events
    cattr_accessor :owner_anchors

    # page links
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
    after_save :update_owner

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

    def public?
      !private?
    end

    def absolute_path
      #TODO: mount point, by way of public_page_url(page)?
      "/" + path
    end


    ## Ownership
    #
    # When it is declared that a class owns pages, a path can be given that places them in the page tree.
    # Here we stash the knowledge of those anchor pages and if necessary, create placeholders for tree-drawing purposes.
    #
    def self.add_anchor_path(path)
      @@owner_anchors ||= []
      @@owner_anchors.push path
    end

    # then at runtime, owner-page creation involves a call to here.
    #
    def self.find_or_create_anchor_page(path)
      where(path: path).first or create_anchor_page(path)
    end

    # which on first run will end up here, working backwards down the branch originally specified in a :base argument
    # finding or creating the pages needed to build a tree out to there.
    #
    def self.create_anchor_page(path)
      path_parts = path.split('/')
      slug = path_parts.pop
      page = where(path: path).first_or_create({
        role: "none",
        title: slug.titlecase,
        slug: slug,
        path: path
      })
      Rails.logger.warn "Page created? #{page.path}: #{page.persisted?.inspect}. Errors: #{page.errors.to_a.inspect}"
      if path_parts.any?
        parent_page = create_anchor_page(path_parts.join('/'))
        page.update_column :parent_id, parent_page.id
      end
      page
    end

    # fetch all pages belonging to given owner object(s), which might be of various types so some hackery is involved.
    #
    def self.owned_by(owners=[])
      owners = [owners].flatten
      results = where("1=0")
      owners.each do |o|
        results = results.or(where(owner_type: o.class.to_s, owner_id: o.id))
      end
      results
    end


    ## Interpolations
    #  can be provided globally by the main application or specificially by a page owner.
    #
    def interpolations
      standard_interpolations.merge(owner_interpolations)
    end

    # override `standard_interpolations` to provide site-wide interpolations available on any page.
    # These might include {{login_form}} or {{user_name}}.
    #
    def standard_interpolations
      {}
    end

    # Add a `cms_interpolations` method to the owner class to provide model-specific interpolations.
    #
    def owner_interpolations
      if owner && owner.respond_to?(:cms_interpolations)
        owner.cms_interpolations
      else
        {}
      end
    end

    # Render performs the interpolations by passing our attributes (usually blocks of html) and interpolation rules to mustache.
    #
    def render(attribute=:published_html)
      if renderable_attributes.include? attribute
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
        published_at: published_at
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
      if owner && owner.respond_to?(:cms_slug_base)
        base = owner.cms_slug_base(self)
      else
        base = [prefix, title].map(&:presence).compact.join(" ")
      end
      raise Chemistry::Error, "cannot derive slug: page owner responds to cms_slug_base but returned value is nil" unless base
      base
    end

    def path_base
      path_parts = if parent
        parent.path.split(/\/+/)
      elsif owner
        owner.anchor_page_path.split(/\/+/)
      else
        []
      end
      path_parts.map(&:presence).compact.map(&:parameterize)
    end


    ## Serializer helpers
    #
    def template_name
      template.title if template
    end


    # Checked after_save to rebuild the section stack for a new template,
    # and on serialization to warn the UI that sections need reloading.
    #
    def template_has_changed?
      saved_change_to_template_id?
    end
    alias :template_has_changed :template_has_changed?  # for serializer


    protected

    def renderable_attributes
      [:published_title, :published_html]
    end

    def set_home_if_first
      if Page.all.empty?
        self.home = true
      end
    end

    def derive_slug_and_path
      if home?
        self.slug = ""
        self.path = ""
      elsif !slug? or !path?
        stem = path_base.join("/")
        slug ||= add_suffix_if_taken(slug_base.parameterize, stem)
        self.slug = slug
        self.path = [stem, slug].join("/")
      end
    end

    def add_suffix_if_taken(base, path)
      slug = base
      addendum = 1
      while Chemistry::Page.find_by(path: [path, slug].join('/'))
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

    def update_owner
      if owner && owner.respond_to? :update_from_page
        owner.update_from_page
      end
    end

  end
end