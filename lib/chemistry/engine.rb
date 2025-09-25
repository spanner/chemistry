require 'kaminari'

module Chemistry
  class Engine < ::Rails::Engine
    isolate_namespace Chemistry
    config.generators.api_only = true
    config.autoload_paths << File.expand_path("../lib", __FILE__)
  end
end
