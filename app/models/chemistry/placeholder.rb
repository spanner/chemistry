module Chemistry
  class Placeholder < ApplicationRecord
    acts_as_paranoid

    belongs_to :template
    acts_as_list scope: :template_id

    belongs_to :section_type

    validates :template, presence: true
    validates :section_type, presence: true
  end
end