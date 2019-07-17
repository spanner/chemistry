module Chemistry
  class Template < ApplicationRecord
    acts_as_paranoid

    has_many :pages, dependent: :nullify
    has_many :placeholders, -> {order(:position)}, dependent: :destroy
    validates :title, presence: true

    after_update :reinit_page_sections

    def section_types
      placeholders.map(&:section_type).map(&:slug)
    end

    def section_types=(list)
      list = list.split(/,\s*/) if list.is_a? String
      list = [list].flatten
      section_types = Chemistry::SectionType.all.each_with_object({}) {|st, hash| hash[st.slug] = st }
      transaction do
        placeholders.clear
        list.each do |st|
          if section_type = section_types[st]
            placeholders.create(section_type: section_type)
          end
        end
      end
      pages.each{|p| p.send(:init_sections)}
    end

    # TODO modify to act only if section list has changed
    def reinit_page_sections
      pages.all.each do |p|
        p.send :init_sections
      end
    end
  end
end