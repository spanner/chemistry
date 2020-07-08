$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "chemistry/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "chemistry"
  s.version     = Chemistry::VERSION
  s.authors     = ["Will Ross"]
  s.email       = ["will@spanner.org"]
  s.homepage    = "https://spanner.org/os/chemistry"
  s.summary     = "A compact and modern content management system."
  s.description = "Add chemistry to your site for a modern and lightweight page-editing toolkit."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", ">= 5.2"
  s.add_dependency 'cancancan'
  s.add_dependency 'paperclip', "~> 6.0"
  s.add_dependency "paperclip-av-transcoder"
  s.add_dependency 'aws-sdk-s3'
  s.add_dependency 'video_info'
  s.add_dependency "kaminari"
  s.add_dependency 'fast_jsonapi'
  s.add_dependency 'paranoia'
  s.add_dependency 'acts_as_list'
  s.add_dependency 'colorize'
  s.add_dependency 'settingslogic'
  s.add_dependency 'searchkick'

  # UI
  s.add_dependency "haml"
  s.add_dependency 'haml_coffee_assets'

  s.add_development_dependency "sqlite3"
end
