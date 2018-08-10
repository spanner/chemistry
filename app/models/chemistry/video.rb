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


    def uploaded_file_url(style=:full, decache=true)
      if file?
        url = file.url(style, decache)
        url.sub(/^\//, Settings.chemistry.host + "/")
      else
        ""
      end
    end


    ## Upload
    #
    # Unusual but possible. Usually we just take a remote_url from youtube or
    # elsewhere and use video_info to get its metadata, including embed code.
    #
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


    ## Serialization
    #
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

    def file_url
      thumbnail_large.presence || uploaded_file_url(:full)
    end

    def thumb_url
      thumbnail_small.presence || uploaded_file_url(:thumb)
    end

    def half_url
      thumbnail_medium.presence || uploaded_file_url(:half)
    end

    def hero_url
      thumbnail_large.presence || uploaded_file_url(:full)
    end

    def original_url
      remote_url.presence || uploaded_file_url(:original)
    end

    protected
  
    def get_metadata
      if remote_url?
        if video = VideoInfo.new(remote_url)
          self.title = video.title
          self.provider = video.provider
          self.thumbnail_large = video.thumbnail_large
          self.thumbnail_medium = video.thumbnail_medium
          self.thumbnail_small = video.thumbnail_small
          self.width = video.width
          self.height = video.height
          self.duration = video.duration
          self.embed_code = video.embed_code
        end
      else
        self.title = file_file_name
        self.provider = 'local'
        self.thumbnail_large = nil
        self.thumbnail_medium = nil
        self.thumbnail_small = nil
        self.width = nil              #
        self.height = nil             # we should be able to get these from the file
        self.duration = nil           #
      end
    end

  end
end