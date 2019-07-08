require 'colorize'

# desc "Explaining what the task does"

namespace :chemistry do
  task :install => :environment do

    Rake::Task["chemistry:install:migrations"].invoke
    Rake::Task["chemistry:seed"].invoke

    # generate initializer if none

  end


  task :seed => :environment do
    if File.exist? Rails.root + "db/import/chemistry/section_types.json"
      path = Rails.root + "db/import/chemistry/section_types.json"
    else
      path = File.expand_path('../../../db/import/chemistry/section_types.json', __FILE__)
    end
    section_types = JSON.parse(File.read(path))
    section_types.each do |st|
      begin
        if section_type = Chemistry::SectionType.find_by(slug: st['slug'])
          section_type.update_attributes(st)
          puts "- Section type #{st['slug']} updated".colorize(:light_green)
        else
          section_type = Chemistry::SectionType.create(st)
          puts "√ Section type: #{st['slug']} created".colorize(:green)
        end
      rescue => e
        puts "x Section type #{st['slug']} could not be created: #{e.message}".colorize(:red)
      end
    end

    if File.exist? Rails.root + "db/import/chemistry/templates.json"
      path = Rails.root + "db/import/chemistry/templates.json"
    else
      path = File.expand_path('../../../db/import/chemistry/templates.json', __FILE__)
    end
    templates = JSON.parse(File.read(path))
    templates.each do |t|
      begin
        if template = Chemistry::Template.find_by(slug: t['slug'])
          template.update_attributes(t)
          puts "- Template #{t['title']} updated".colorize(:light_green)
        else
          section_types = t.delete('section_types')
          template = Chemistry::Template.create(t)
          template.section_types = section_types
          puts "√ Template: #{t['title']} created".colorize(:green)
        end
      rescue => e
        puts "x Template #{t['title']} could not be created: #{e.message}".colorize(:red)
      end
    end

  end

end

