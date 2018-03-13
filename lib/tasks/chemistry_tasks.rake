require 'colorize'

# desc "Explaining what the task does"

namespace :chemistry do
  task :install => :environment do

    Rake::Task["chemistry:install:migrations"].invoke
    Rake::Task["chemistry:seed"].invoke

    # generate initializer if none

  end


  task :seed => :environment do
    section_types = JSON.parse(File.read(File.expand_path('../../../db/import/v1/section_types.json', __FILE__)))
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

    templates = JSON.parse(File.read(File.expand_path('../../../db/import/v1/templates.json', __FILE__)))
    templates.each do |t|
      begin
        if template = Chemistry::Template.find_by(title: t['title'])
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

