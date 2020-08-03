require "open-uri"

module Chemistry
  class Document < ApplicationRecord
    acts_as_paranoid
    belongs_to :user, class_name: Chemistry.config.user_class, foreign_key: Chemistry.config.user_key

    # TODO extract text, thumbnail image
    has_attached_file :file, preserve_files: true
    do_not_validate_attachment_file_type :file

    before_validation :read_remote_url

    def file_url(style=:original, decache=true)
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
 
    def url
      file_url(:original)
    end

    ## Elasticsearch indexing
    #
    searchkick searchable: [:title, :file_name],
               word_middle: [:title, :file_name]

    def search_data
      {
        title: title,
        file_name: file_name,
        file_type: file_type,
        file_size: file_size,
        created_at: created_at,
        user: user_id,
        url: url
      }
    end

    protected

    def read_remote_url
      if remote_url? && !file?
        self.file = open(remote_url)
      end
    end

  end
end