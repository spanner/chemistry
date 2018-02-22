require 'video_info'

module Chemistry
  class Video < ApplicationRecord
    acts_as_paranoid

    has_attached_file :file,
      preserve_files: true,
      processors: [:transcoder],
      styles: {
        thumb: { geometry: "48x48#", format: 'png', time: 0 },
        half: { geometry: "540x304<", format: 'jpg', time: 0 },
        full: { geometry: "1120x630<", format: 'jpg', time: 0 }
      }

    validates_attachment_content_type :file, :content_type => /\Avideo/
    before_validation :get_metadata

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
      # if uploaded_file = image.queued_for_write[:original]
      #   file = uploaded_file.send :destination
      #   geometry = Paperclip::Geometry.from_file(file)
      #   self.file_width = geometry.width
      #   self.file_height = geometry.height
      #   self.file_duration = geometry.height
      # end
      # true
    end
  
    def get_metadata
      if remote_url?
        if video = VideoInfo.new(remote_url)
          self.title = video.title
          self.provider = video.provider
          self.thumbnail_large = video.thumbnail_large
          self.thumbnail_medium = video.thumbnail_medium
          self.thumbnail_small = video.thumbnail_small
          self.file_width = video.width
          self.file_height = video.height
          self.file_duration = video.duration
          self.embed_code = video.embed_code
        end
      else
        self.title = file_file_name
        self.provider = 'local'
        self.thumbnail_large = nil
        self.thumbnail_medium = nil
        self.thumbnail_small = nil
        self.file_width = nil
        self.file_height = nil
        self.file_duration = nil
      end
    end
  
  end
end