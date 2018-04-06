module Chemistry::Concerns::Tagged
  extend ActiveSupport::Concern

  included do
    has_many :term_attachments, as: :attachee, class_name: "Chemistry::TermAttachment"
    has_many :terms, through: :term_attachments, class_name: "Chemistry::Term"
  end

  def tag_list
    tag_names.join(",")
  end

  def tag_names
    tags.map(&:name).uniq
  end

  def tags_with_synonyms
    tags.includes(:tag_synonyms).map(&:with_synonyms).flatten.uniq.join(' ')
  end

  def tag_list=(tag_list)
    self.tags = tag_list.split(/,\s*/).map { |t| Tag.find_or_create(t) }
  end

  # To support ancient keywords= interface

  def keywords
    self.tags.pluck(:name).compact.uniq.join(', ')
  end

  def keywords_before_type_cast   # for form_helper
    keywords
  end

  def keywords=(somewords="")
    if somewords.blank?
      self.tags.clear
    else
      self.tags = Droom::Tag.from_list(somewords)
    end
  end

end