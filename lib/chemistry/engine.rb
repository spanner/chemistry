require 'kaminari'

module Chemistry
  class Engine < ::Rails::Engine
    isolate_namespace Chemistry
    config.generators.api_only = true
    config.assets.paths << Chemistry::Engine.root.join('node_modules')
    config.autoload_paths << File.expand_path("../lib", __FILE__)
  end
end
