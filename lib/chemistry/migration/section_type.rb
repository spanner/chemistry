module Chemistry
  class SectionType < ApplicationRecord
    has_many :sections

    before_validation :derive_slug

    validates :title, presence: true
    validates :slug, presence: true
    validates :template, presence: true

    protected

    def derive_slug
      self.slug = (self.slug.presence || self.title).parameterize
    end

  end
end