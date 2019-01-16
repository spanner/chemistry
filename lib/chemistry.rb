require 'chemistry/version'
require "chemistry/engine"
require "json"
require "searchkick"
require "paperclip"
require "paperclip/av/transcoder"
require "acts_as_list"
require "paranoia"
require 'haml_coffee_assets'

module Chemistry
  class Error < StandardError; end

  class << self
    mattr_accessor :configured,
                   :layout,
                   :public_layout,
                   :host,
                   :protocol,
                   :ui_path,
                   :api_url,
                   :cookie_domain,
                   :production_host,       #
                   :staging_host,          # for feature detection in UI
                   :dev_host,              #
                   :ui_locales,
                   :user_class,
                   :default_per_page

    self.layout = "chemistry/application"
    self.public_layout = "application"
    self.api_url = "/cms/api"
    self.ui_locales = ['en']
    self.default_per_page = 10
  end

  def self.configure
    yield self
    self.configured = true
  end

  # Never call this method from an asset, unless you like stacking.
  def self.locale_urls
    urls = self.ui_locales.each_with_object({}) do |locale, hash|
      hash[locale] = ActionController::Base.helpers.asset_url("chemistry/#{locale}.json")
    end
    urls
  end

end
