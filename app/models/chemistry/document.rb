require "open-uri"
module Chemistry
  class Document < ApplicationRecord
    acts_as_paranoid
    belongs_to :page

    has_attached_file :file, preserve_files: true                   # TODO extract text, image of front page
    do_not_validate_attachment_file_type :file

    before_validation :read_remote_url
  
    def file_url(style=:original, decache=true)
      if file?
        url = file.url(style, decache)
        url.sub(/^\//, "#{Settings.api.protocol}://#{Settings.api.host}/")
      else
        ""
      end
    end
  
    def file_name=(name)
      self.file_file_name = name
    end
  
    protected
    
    def read_remote_url
      if remote_url? && !file?
        self.file = open(remote_url)
      end
    end

  end
end