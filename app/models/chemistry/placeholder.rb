module Chemistry
  class Placeholder < ApplicationRecord
    acts_as_paranoid

    belongs_to :template
    acts_as_list scope: :template_id
    validates :template, presence: true
  end
end