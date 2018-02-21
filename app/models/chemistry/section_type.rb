module Chemistry
  class SectionType < ApplicationRecord
    acts_as_paranoid
    has_many :sections
    has_many :placeholders

    # svg file for selection-UI display
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
  end
end