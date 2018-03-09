module Chemistry
  class Section < ApplicationRecord
    acts_as_paranoid

    belongs_to :page
    # acts_as_list scope: :page_id

    belongs_to :section_type
    validates :page, presence: true
    validates :section_type, presence: true

    scope :other_than, -> sections {
      where.not(id: sections.map(&:id))
    }


    # for serialization

    def section_type_slug
      section_type.slug if section_type
    end

  end
end