require "chemistry/config"
require 'chemistry/version'
require "chemistry/engine"
require "chemistry/content_scrubber"
require "chemistry/inline_scrubber"
require "json"
require "searchkick"
require "paperclip"
require "paperclip/av/transcoder"
require "acts_as_list"
require 'haml_coffee_assets'

module Chemistry
  mattr_accessor :config
  mattr_accessor :configured
  @@config = Chemistry::Config.new

  class Error < StandardError; end

  class << self
    #
    # Chemistry.configure do |config|
    #   config.public_layout = "freshnewlook"
    # end
    #
    def configure
      yield @@config
      self.configured = true
    end

    # pp = Chemistry.config.default_per_page
    #
    def config
      @@config
    end
  end

end
