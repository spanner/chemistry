require "open-uri"
module Chemistry
  class Image < ApplicationRecord
    acts_as_paranoid
    belongs_to :user, class_name: Chemistry.user_class

    has_attached_file :file,
      preserve_files: true,
      styles: {
        thumb: "96x96#",
        half: "560x",
        full: "1120x",
        hero: "1600x900#"
      },
      convert_options: {
        thumb: "-strip",
        half: "-quality 40 -strip",
        full: "-quality 40 -strip",
        hero: "-quality 25 -strip",
      }

    validates_attachment_content_type :file, :content_type => /\Aimage/

    def file_url(style=:full, decache=true)
      if file?
        url = file.url(style, decache)
        url.sub(/^\//, Settings.chemistry.host + "/")
      else
        ""
      end
    end

    def file_data=(data)
      if data
        self.file = data
      else
        self.file = nil
      end
    end
  
    def file_name=(name)
      self.file_file_name = name
    end

    def file_type=(content_type)
      self.file_content_type = content_type
    end

    def remote_url=(url)
      if url
        self.file = open(url)
      end
    end

    ## serialization

    def title
      read_attribute(:title).presence || file_file_name
    end

    def file_name
      file_file_name
    end

    def file_type
      file_content_type
    end

    def file_size
      file_file_size
    end
 
    def thumb_url
      file_url(:thumb)
    end

    def half_url
      file_url(:half)
    end

    def hero_url
      file_url(:hero)
    end

    def original_url
      file_url(:original)
    end
   
  end
end