module Chemistry
  class Page < ApplicationRecord
    acts_as_paranoid
    belongs_to :parent, class_name: 'Chemistry::Page', optional: true
    belongs_to :template, optional: true

    has_many :sections, -> {order(position: :asc)}, dependent: :destroy
    has_many :documents, -> {order(position: :asc)}, dependent: :destroy
    acts_as_list column: :nav_position

    before_validation :derive_slug
    before_validation :derive_path
    before_validation :get_excerpt
    before_validation :set_home_if_first

    validates :title, presence: true
    validates :path, uniqueness: {conditions: -> { where(deleted_at: nil) }}

    scope :undeleted, -> { where(deleted_at: nil) }
    scope :published, -> { undeleted.where.not(published_at: nil) }

    scope :home, -> { published.where(home: true).limit(1) }
    scope :nav, -> { published.where(nav: true) }
    scope :from_path, -> path { published.where(path: path) }


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


    protected

    def set_home_if_first
      if Page.all.empty?
        self.home = true
      end
    end

    def derive_slug
      self.slug = (self.slug.presence || self.title).parameterize
    end

    def derive_path
      if home?
        self.path = "/"
      elsif parent
        path_parts = []
        path_parts += parent.path.split(/\/+/).map(&:parameterize)
        path_parts.push slug
        self.path = path_parts.compact.join('/')
      end
    end

    def get_excerpt
      #todo: truncated body of first section that has one
    end

    def init_sections
      if template
        revised_sections = []

        # populate in order dictated by template, reusing any existing sections
        template.placeholders.each do |placeholder|
          revised_sections << sections.other_than(revised_sections).first_or_create(section_type_id: placeholder.section_type_id)
        end
        # note leftovers
        leftover_sections = sections.other_than(revised_sections)
        # assign sequence
        revised_sections.each.with_index do |section, i|
          section.update_column(:position, i)
        end
        # detach (but keep) leftovers
        leftover_sections.update_all(position: nil, detached: true)

        self.sections = revised_sections + leftover_sections
      end
    end

  end
end