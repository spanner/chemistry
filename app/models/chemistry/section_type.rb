module Chemistry
  class SectionType < ApplicationRecord
    acts_as_paranoid
    has_many :sections
    has_many :placeholders

    # usually an svg file for selection-UI display
    has_attachment :icon

    # default image for placeholder display
    has_attachment :image,
      styles: {
        thumb: "48x48#",
        half: "540x",
        full: "1120x",
        hero: "1600x900"
      },
      convert_options: {
        thumb: "-strip",
        half: "-quality 40 -strip",
        full: "-quality 40 -strip",
        hero: "-quality 25 -strip",
      }

    before_validation :derive_slug

    validates :title, presence: true
    validates :slug, presence: true
    validates :template, presence: true
    validates_attachment_content_type :icon, :content_type => /\Aimage/
    validates_attachment_content_type :image, :content_type => /\Aimage/

    def image_url(style=:original, decache=true)
      if image?
        image.url(style, decache)
      else
        ""
      end
    end

    def icon_url
      if image?
        icon.url(:original) if icon?
      else
        ""
      end
    end

    protected

    def derive_slug
      self.slug = (self.slug.presence || self.title).parameterize
    end

  end
end