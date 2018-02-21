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
  s.summary     = "A compact and pluggable single-site CMS engine."
  s.description = "Add chemistry to your site for a modern and lightweight page-editing toolkit."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 5.1.4"

  s.add_development_dependency "sqlite3"
end
