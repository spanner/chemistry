module Chemistry
  class Section < ApplicationRecord
    acts_as_paranoid
    belongs_to :page
    belongs_to :image
    belongs_to :video

    acts_as_list scope: :page_id

    validates :page, presence: true

  end
end