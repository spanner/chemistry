module Chemistry
  class Section < ActiveRecord::Base
    belongs_to :page

    belongs_to :section_type

    def all_html
      html = [primary_html, secondary_html, background_html].map(&:presence).compact.join("\n")
      ApplicationController.helpers.sanitize(html)
    end

  end
end