require 'mustache'

module Chemistry
  class Page < ApplicationRecord
    acts_as_paranoid
    belongs_to :template, optional: true
    belongs_to :parent, class_name: 'Chemistry::Page', optional: true
    belongs_to :owner, polymorphic: true
    cattr_accessor :owner_anchors

    has_many :child_pages, class_name: 'Chemistry::Page', foreign_key: :parent_id
    has_many :sections, -> {order(position: :asc)}, dependent: :destroy
    acts_as_list column: :nav_position

    has_many :page_terms
    has_many :terms, through: :page_terms

    before_validation :derive_slug_and_path
    before_validation :get_excerpt
    before_validation :set_home_if_first

    validates :title, presence: true
    validates :path, uniqueness: {conditions: -> { where(deleted_at: nil) }}

    after_create :init_sections
    before_update :note_publication_date
    after_update :reinit_sections_if_changed
    after_save :update_owner

    scope :undeleted, -> { where(deleted_at: nil) }
    scope :published, -> { undeleted.where.not(published_at: nil) }
    scope :latest, -> { order(published_at: :desc) }
    scope :with_parent, -> page { where(parent_id: page.id) }

    scope :home, -> { where(home: true).limit(1) }
    scope :nav, -> { where(nav: true) }

    scope :with_path, -> path { where(path: path) }

    def published?
      published_at?
    end

    ## Sections
    #
    # It's not pretty, but it's a lot nicer than accepts_nested_attributes_for.
    #
    def sections_data=(section_data=nil)
      if section_data
        old_section_ids = sections.map(&:id)
        new_section_ids = []
        updated_section_ids = []
        section_data.each do |data|
          section_id = data.delete(:id)
          if section_id
            if section = sections.find(section_id)
              section.update_attributes(data)
              new_section_ids.push section_id
            else
              # raise not found
            end
          elsif !data[:deleted_at]
            if new_section = sections.create(data)
              new_section_ids.push new_section.id
            else
              # raise not valid
            end
          end
        end
        deleted_section_ids = old_section_ids - new_section_ids
        deleted_section_ids.each do |did|
          sections.find(did).destroy
        end
        sections.reload
      else
        # so, delete them all?
      end
      self.touch
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
      create_anchor_page(path.split('/'))
    end

    def self.create_anchor_page(path_parts)
      path = path_parts.join('/')
      slug = path_parts.pop
      page = where(path: path).first_or_create({
        content: "none",
        title: slug.titlecase,
        slug: slug,
        path: path
      })
      Rails.logger.warn "Page created? #{page.persisted?.inspect}. Errors: #{page.errors.to_a.inspect}"
      if path_parts.any?
        page.parent = create_anchor_page(path_parts)
        page.save if page.changed?
      end
      page
    end

    # For serialization
    #
    def anchor
      Chemistry::Page.owner_anchors.include?(path)
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

    def template_slug
      template.slug if template
    end

    def slug_base
      if owner && owner.respond_to?(:cms_slug_base)
        owner.cms_slug_base(self)
      else
        title
      end
    end

    def path_base
      path_parts = if parent
        parent.path.split(/\/+/)
      elsif owner
        owner.cms_path_base.split(/\/+/)
      else
        []
      end
      path_parts.map(&:presence).compact.map(&:parameterize)
    end

    def template_name
      template.title if template
    end


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

    def add_suffix_if_taken(slug_base, path)
      slug = slug_base
      addendum = 1
      while Chemistry::Page.find_by(path: [path, slug].join('/'))
        slug = slug_base + addendum
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
      if template
        revised_sections = []

        # populate in order dictated by template, reusing any existing sections of matching type
        template.placeholders.each.with_index do |placeholder, i|
          section = sections.other_than(revised_sections).where(section_type_id: placeholder.section_type_id).first_or_create
          section.update_column :position, i
          if i == 0 && !section.title
            section.update_column :title, title
          end
          revised_sections << section
        end

        # note leftovers
        leftover_sections = sections.other_than(revised_sections)

        # detach (but keep) leftovers
        leftover_sections.update_all(position: nil, detached: true)

        # assign new sections
        self.sections = revised_sections + leftover_sections
      end
    end

    def reinit_sections_if_changed
      init_sections if template && (sections.empty? || saved_change_to_template_id?)
    end

    protected

    def update_owner
      if owner and owner.respond_to? :update_from_page
        owner.update_from_page
      end
    end

  end
end