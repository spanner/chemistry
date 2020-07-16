require 'colorize'

# desc "Explaining what the task does"

namespace :chemistry do
  task :install => :environment do

    Rake::Task["chemistry:install:migrations"].invoke
    Rake::Task["chemistry:seed"].invoke

    # generate initializer if none

  end

  # desc "Migrate page content from v1 blocks to v2 page markup"
  task :migrate => :environment do
    section_types = SectionType.all
    head_section_types = SectionType.where(slug: %w{hero serialhead zonehead homehead})
    body_section_types = SectionType.where(slug: %w{standfirst standard})
    Page.all.each do |page|
      sections = page.sections
      head_sections = sections.find {|s| head_section_types.include?(s.section_type) }
      body_sections = sections.find {|s| body_section_types.include?(s.section_type) }


      # 1. get best page head and extract image id
      # 2. concatenate body sections while wrapping assets and not-asset sequences
      # ( possibly in UI)
      
    end
  end

end

