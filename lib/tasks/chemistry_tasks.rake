require 'colorize'

# desc "Explaining what the task does"

namespace :chemistry do
  task :install => :environment do

    Rake::Task["chemistry:install:migrations"].invoke
    Rake::Task["chemistry:seed"].invoke

    # generate initializer if none

  end


  task :seed => :environment do

    section_types = JSON.parse(File.read(File.expand_path('../../../db/import/section_types_v1.json', __FILE__)))
    section_types.each do |st|
      begin
        if Chemistry::SectionType.find_by(slug: st['slug'])
          puts "- Section type #{st['slug']} exists".colorize(:light_white)
        else
          Chemistry::SectionType.create(st)
          puts "√ Section type: #{st['slug']} created".colorize(:green)
        end
      rescue => e
        puts "x Section type #{st['slug']} could not be created: #{e.message}".colorize(:red)
      end
    end
  end

end

