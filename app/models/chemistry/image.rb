require "open-uri"
module Chemistry
  class Image < ApplicationRecord
    acts_as_paranoid

    has_attached_file :file,
      preserve_files: true,
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

    validates_attachment_content_type :file, :content_type => /\Aimage/

    before_validation :read_remote_url
    after_post_process :read_dimensions
  
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
    
    # *read_dimensions* is called after post processing to record in the database the original width, height
    # and extension of the uploaded file. At this point the file queue will not have been flushed but the upload
    # should still be in the queue.
    #
    def read_dimensions
      if uploaded_file = file.queued_for_write[:original]
        file = uploaded_file.send :destination
        geometry = Paperclip::Geometry.from_file(file)
        self.file_width = geometry.width
        self.file_height = geometry.height
      end
      true
    end
  
    def read_remote_url
      if remote_url? && !file?
        self.file = open(remote_url)
      end
    end
  
  end
end