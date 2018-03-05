module Chemistry
  class Page < ApplicationRecord
    acts_as_paranoid
    belongs_to :parent, class_name: Chemistry::Page, optional: true

    has_many :sections, -> {order(:position)}, dependent: :destroy
    has_many :documents, -> {order(:position)}, dependent: :nullify
    acts_as_list column: :nav_position

    before_validation :derive_slug
    before_validation :derive_path
    before_validation :set_home_if_first

    validates :title, presence: true
    validates :path, uniqueness: {conditions: -> { where(deleted_at: nil) }}

    scope :undeleted, -> { where(deleted_at: nil) }
    scope :published, -> { undeleted.where.not(published_at: nil) }
    scope :home, -> { published.where(home: true).limit(1) }
    scope :nav, -> { published.where(nav: true) }

    # It's not pretty, but it's a lot nicer than accepts_nested_attributes_for.
    #
    def sections=(section_data=nil)
      if section_data
        old_section_ids = sections.map(&:id)
        new_section_ids = []
        updated_section_ids = []
        section_data.each do |data|
          section_id = data.delete(:id)
          if section_id
            if section = sections.find(section_id)
              section.update_attributes(data)
              new_section_ids.push section_id
            else
              # raise not found
            end
          elsif !data[:deleted_at]
            if new_section = sections.create(data)
              new_section_ids.push new_section.id
            else
              # raise not valid
            end
          end
        end
        deleted_section_ids = old_section_ids - new_section_ids
        deleted_section_ids.each do |did|
          sections.find(did).destroy
        end
        sections.reload
      else
        # so we delete them all?
      end
      self.touch
    end

    ## Publication
    #
    # Pages are published to the filesystem as static html for direct delivery by the web server.
    #
    # The are first composed by placing page html elements into the site html wrapper.
    #
    def publish!
      path_and_filename = path.sub(/^\//, '')
      path_and_filename = "index" if path_and_filename.blank?
      file = Pathname.new(Settings.pub.root).join(site.slug, path_and_filename + ".html").cleanpath
      html = self.compose
      FileUtils.mkdir_p(file.dirname)
      File.open(file, 'w') { |f| f.write html }
      self.update_column(:published_at, Time.now)
    end

    protected

    def set_home_if_first
      if Page.all.empty?
        self.home = true
      end
    end

    def derive_slug
      self.slug = (self.slug.presence || self.title).parameterize
    end

    def derive_path
      if home?
        self.path = ""
      elsif parent
        path_parts = []
        path_parts += parent.path.split(/\/+/).map(&:parameterize)
        path_parts.push slug
        self.path = path_parts.compact.join('/')
      end
    end

  end
end