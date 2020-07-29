require 'video_info'

module Chemistry
  class Video < ApplicationRecord
    acts_as_paranoid
    belongs_to :user, class_name: Chemistry.config.user_class, foreign_key: Chemistry.config.user_key

    has_attached_file :file,
      preserve_files: true,
      processors: [:transcoder],
      styles: {
        mp4: { format: "mp4"},
        thumb: { geometry: "48x48#", format: 'png', time: 0 },
        half: { geometry: "540x304<", format: 'jpg', time: 0 },
        full: { geometry: "1120x630<", format: 'jpg', time: 0 }
      }

    validates_attachment_content_type :file, :content_type => /\Avideo/
    before_validation :get_metadata

    scope :created_by, -> users {
      users = [users].flatten
      where(user_id: users.map(&:id))
    }

    def uploaded_file_url(style=:full, decache=true)
      if file?
        url = file.url(style, decache)
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

    def mp4_url
      uploaded_file_url(:mp4)
    end

    ## Elasticsearch indexing
    #
    searchkick searchable: [:title],
               word_start: [:title],
               highlight: [:title]

    def search_data
      {
        title: title,
        provider: provider,
        width: width,
        height: height,
        duration: duration,
        file_name: file_name,
        file_type: file_type,
        file_size: file_size,
        created_at: created_at,
        user: user_id,
        embed_code: embed_code,
        created_at: created_at,
        urls: {
          original: original_url,
          hero:  hero_url,
          full: full_url,
          half: half_url,
          thumb: thumb_url,
          mp4: mp4_url
        }
      }
    end

    protected

    def get_metadata
      Rails.logger.warn "fetching metadata for remote_url #{remote_url}"
      if remote_url?
        # unless remote_url =~ /^http/
        #   remote_url = "http://www.youtube.com/watch?v=#{remote_url}"
        # end
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