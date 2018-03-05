module Chemistry
  class Section < ApplicationRecord
    acts_as_paranoid

    belongs_to :page
    acts_as_list scope: :page_id

    belongs_to :section_type
    belongs_to :image
    belongs_to :video
    belongs_to :document

    validates :page, presence: true
    validates :section_type, presence: true
  end
end