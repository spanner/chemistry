require 'colorize'
require 'chemistry/migration/section_type'
require 'chemistry/migration/section'

namespace :chemistry do
  # desc "Prepare an empty chemistry site."
  task :install => :environment do

    Rake::Task["chemistry:install:migrations"].invoke
    Rake::Task["db:migrations"].invoke
    Rake::Task["chemistry:seed"].invoke
    # TODO: generate initializer
  end

  # desc "Seed demo chemistry page."
  task :seed => :environment do


  end

  # desc "Migrate page content from v1 blocks to v2 page markup"
  task :migrate => :environment do
    head_section_types = Chemistry::SectionType.where(slug: %w{hero homehead statement}).map(&:id)
    body_section_types = Chemistry::SectionType.where(slug: %w{standfirst standard}).map(&:id)
    Page.where(deleted_at: nil).each do |page|
      sections = Chemistry::Section.where(deleted_at: nil, detached: false, page_id: page.id)
      head_sections = sections.select {|s| head_section_types.include?(s.section_type_id) }
      body_sections = sections.select {|s| body_section_types.include?(s.section_type_id) }

      puts "* #{page.title}"
      puts "  #{head_sections.count} heads"
      puts "  #{body_sections.count} bodies"

      if head = head_sections.first
        if html = head.background_html.presence || head.primary_html.presence || head.secondary_html
          matches = html.match /data\-asset\-id\s*=\"(\d+)\"/
          if asset_id = matches[1]
            if image = Chemistry::Image.find_by(id: asset_id)
              page.image = image
              page.masthead = %{
<div class="images cms-slides"><div class="cms-slider"><div class="cms-slide-holder">
  <figure class="image cms-slide" data-image="#{image.id}">
    <img class='image' src="#{image.file_url(:hero)}">
    <figcaption></figcaption>
  </figure>
</div></div></div>
}
            end
          end
        end
      end

      page.content = body_sections.map(&:all_html).join("\n\n")
      page.save
    end
  end
end

