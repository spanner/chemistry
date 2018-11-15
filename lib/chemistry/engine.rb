require 'kaminari'

module Chemistry
  class Engine < ::Rails::Engine
    isolate_namespace Chemistry
    config.generators.api_only = true
    config.assets.paths << Chemistry::Engine.root.join('node_modules')
    config.assets.precompile += %w( chemistry/en.json chemistry/cms.css chemistry/public.css chemistry/cms.js chemistry/public.js)
  end
end
