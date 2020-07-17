module Chemistry
  module Concerns::Slugged
    extend ActiveSupport::Concern

    self.included do
      validates :slug, presence: true
      before_validation :derive_slug
    end

    def slug_source
      title
    end

    def derive_slug
      if slug?
        self.slug = slug.parameterize
      else
        self.short_title ||= title
        unique_slug = slug_base = self.slug || self.slug_source
        addendum = 1
        while self.class.other_than(self).find_by_slug(unique_slug)
          unique_slug = "#{slug_base}-#{addendum}"
          addendum += 1
        end
        self.slug = unique_slug
      end
    end

  end
end