require "open-uri"
module Chemistry
  class Image < ApplicationRecord
    belongs_to :user, class_name: Chemistry.config.user_class, foreign_key: Chemistry.config.user_key

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

    scope :created_by, -> users {
      users = [users].flatten
      where(user_id: users.map(&:id))
    }

    def file_url(style=:full, decache=true)
      if file?
        url = file.url(style, decache)
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

    def full_url
      file_url(:full)
    end

    def hero_url
      file_url(:hero)
    end

    def original_url
      file_url(:original)
    end

    ## Elasticsearch indexing
    #
    searchkick searchable: [:title, :file_name],
               word_start: [:title, :file_name]

    def search_data
      {
        title: title,
        file_name: file_name,
        file_type: file_type,
        file_size: file_size,
        created_at: created_at,
        user: user_id,
        urls: {
          original: original_url,
          hero:  hero_url,
          full: full_url,
          half: half_url
        }
      }
    end

  end
end