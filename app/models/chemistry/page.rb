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

    # metadata
    has_many :page_terms
    has_many :terms, through: :page_terms

    # first masthead image is extracted for display in lists
    belongs_to :image, optional: true

    before_validation :derive_slug_and_path
    before_validation :get_excerpt
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

    def self.owned_by(owners=[])
      owners = [owners].flatten
      results = where("1=0")
      owners.each do |o|
        results = results.or(where(owner_type: o.class.to_s, owner_id: o.id))
      end
      results
    end

    def self.published_page_at(path)
      where(path: path).where.not(published_at: nil).first
    end

    def published?
      published_at?
    end

    def populated?
      sections.where("primary_html IS NOT NULL or secondary_html IS NOT NULL").any?
    end

    def public?
      !private?
    end

    def empty
      !populated?
    end

    def absolute_path
      #TODO: mount point, by way of public_page_url(page)?
      "/" + path
    end

    def summary_or_excerpt
      summary.presence || excerpt
    end


    ## Terms
    #
    def term_names
      terms.pluck(:term).uniq
    end

    def term_list
      term_names.join(", ")
    end

    def terms_with_synonyms
      terms.includes(:term_synonyms).map(&:with_synonyms).flatten.uniq.join(' ')
    end

    # public tagging interface looks like this:
    #
    def keywords
      term_list
    end

    def keywords=(somewords)
      if somewords.blank?
        self.terms.clear
      else
        self.terms = Chemistry::Term.from_list(somewords)
      end
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


    ## Interpolations
    #  are provided globally by the main application or specificially by a page owner.
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
    def render(attribute=:published_content)
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

    scope :search_import, -> { includes(:template) }

    def search_data
      {
        title: title,
        content: clean_rendered_html,
        terms: terms_with_synonyms,
        page_type: template_slug,
        path: path,
        published: published?,
        published_at: published_at
      }
    end

    def clean_rendered_html
      ActionController::Base.helpers.strip_tags(rendered_html)
    end

    def image_url
      image.file_url(:hero) if image
    end

    def icon_url
      image.file_url(:thumb) if image
    end

    def template_slug
      template.slug if template
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
      [:display_title, :rendered_html]
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

    def get_excerpt
      #todo: truncated body of first section that has one
    end

    # tiny little bodge here to make sure that published_at ends up being later than updated_at.
    def note_publication_date
      self.published_at = Time.now + 2.seconds if will_save_change_to_rendered_html?
    end

    def init_sections
      Rails.logger.warn "init_sections"
      if template
        revised_sections = []

        # populate in order dictated by template, reusing any existing sections of matching type
        existing_sections = sections.to_a
        section_placeholders = template.placeholders.to_a
        pos_base = 1

        # existing header section: change type in situ
        if existing_sections.any? && section_placeholders.any?
          header_section = existing_sections.shift
          header_section_placeholder = section_placeholders.shift
          if header_section.section_type_id != header_section_placeholder.section_type_id
            header_section.section_type_id = header_section_placeholder.section_type_id
            header_section.move_to_top
            pos_base += 1
          end
          revised_sections.push(header_section)
        end

        # everything else: shuffle into order, adding new sections where none of that type is available.
        section_placeholders.each.with_index do |placeholder, i|
          section = sections.other_than(revised_sections).where(section_type_id: placeholder.section_type_id).first_or_create
          section.update_attributes({
            detached: false,
            position: i + pos_base
          })
          section.save
          revised_sections << section
        end

        # note leftovers
        leftover_sections = sections.other_than(revised_sections)

        # detach (but keep) leftovers
        leftover_sections.update_all(position: nil, detached: true)

        # and a bit of prep/housekeeping
        if header_section = revised_sections.first
          header_section.prefix = prefix unless header_section.prefix?
          header_section.title = title unless header_section.title?
          header_section.save if header_section.changed?
        end

        # assign new sections (which should give them position in their present order)
        self.sections = revised_sections + leftover_sections
      end
    end

    def reinit_sections_if_changed
      init_sections if template && (sections.empty? || template_has_changed?)
    end

    def update_owner
      Rails.logger.warn "update_owner"
      if owner
        if owner.respond_to? :update_from_page
          owner.update_from_page
        end
      end
    end

  end
end