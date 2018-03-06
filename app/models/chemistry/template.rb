module Chemistry
  class Template < ApplicationRecord
    acts_as_paranoid
    acts_as_list

    has_many :placeholders, -> {order(:position)}, dependent: :destroy
    validates :title, presence: true

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
    end

    # TODO on change of placeholder sequence,
    # assign to all existing pages by find_or_creating in the existing sections then pending any no longer mentioned.
  end
end