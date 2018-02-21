module Chemistry
  class Template < ApplicationRecord
    acts_as_paranoid

    has_many :placeholders, -> {order(:position)}, dependent: :destroy
    validates :title, presence: true

  end
end