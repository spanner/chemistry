module Chemistry
  class Section < ApplicationRecord
    acts_as_paranoid

    belongs_to :page
    acts_as_list scope: :page_id
    validates :page, presence: true

    belongs_to :image
    belongs_to :video
  end
end