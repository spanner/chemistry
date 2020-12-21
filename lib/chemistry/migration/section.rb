module Chemistry
  class Section < ApplicationRecord
    belongs_to :page

    belongs_to :section_type

    def all_html
      [primary_html, secondary_html, background_html].map(&:presence).compact.join("\n")
    end

  end
end