module Chemistry
  class PageCategory < ApplicationRecord
    include Concerns::Slugged

    has_many :pages
    validates :title, presence: true
    default_scope -> { order(:title) }

    def self.for_selection
      order(:title).map{|pc| [pc.title, pc.id] }
    end
  end
end