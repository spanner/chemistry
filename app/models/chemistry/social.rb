# == Schema Information
#
# Table name: social_links
#
#  id                  :integer          not null, primary key
#  social_link_type_id :integer
#  serial_id           :integer
#  name                :string(255)
#  url                 :string(255)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  platform            :string(255)
#  reference           :string(255)
#

module Chemistry
  class Social < ApplicationRecord
    belongs_to :page
    acts_as_list scope: :page_id

    validates :platform, presence: true
    validates :page, presence: true

    scope :website, -> {
      where(platform: "web")
    }

    scope :populated, -> {
      where('url IS NOT NULL AND TRIM(url) <> ""')
    }

    # for serialization

    def normalized_url
      if url.present?
        case (platform.presence || "web").downcase
        when "instagram"
          url_with_base("instagram.com")
        when "facebook"
          url_with_base("facebook.com")
        when "twitter"
          url_with_base("twitter.com")
        else 
          self.class.normalize_url(url)
        end
      end
    end

    def app_url
      if url.present?
        case (platform.presence || "web").downcase
        when "instagram"
          instagram_app_url
        when "facebook"
          facebook_app_url
        when "twitter"
          twitter_app_url
        else
          ""
        end
      end
    end

    def instagram_app_url
      id = url_without_base("instagram.com")
      id = url.sub(/^@/, '').strip
      "instagram://user?username=#{id}"
    end

    def facebook_app_url
      id = url_without_base("facebook.com")
      id = url.sub(/^@/, '').strip
      "fb://page/#{id}"
    end

    def twitter_app_url
      id = url_without_base("twitter.com")
      id = url.sub(/^@/, '').strip
      "twitter://user?screen_name=#{id}"
    end

    protected

    def url_with_base(base)
      if url =~ /#{Regexp.quote(base)}/i
        self.class.normalize_url(url)
      else
        path = url.sub(/^@/, '').strip
        URI.join("https://#{base}", path.strip).to_s
      end
    rescue URI::InvalidURIError
      ""
    end

    def url_without_base(base)
      social_id = url
      social_id.sub!(/http(s)?:\/\/(www\.)?/, '')
      social_id.sub!(/#{Regexp.quote(base)}(\/)?/, '')
      social_id
    end

    def self.normalize_url(url="")
      url = "https://#{url}" unless url.blank? or url =~ /^https?:\/\//
      url.strip
    end

    def touch_page
      page.touch
    end

  end
end