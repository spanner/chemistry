module Chemistry::Concerns::HasTags
  extend ActiveSupport::Concern

  included do
    has_many :term_attachments, as: :attachee, class_name: "Chemistry::TermAttachment"
    has_many :terms, through: :term_attachments, class_name: "Chemistry::Term"
  end

  def term_list
    term_names.join(",")
  end

  def term_names
    terms.map(&:name).uniq
  end

  def terms_with_synonyms
    terms.includes(:term_synonyms).map(&:with_synonyms).flatten.uniq.join(' ')
  end

  def term_list=(term_list)
    self.terms = term_list.split(/,\s*/).map { |t| Chemistry::Term.find_or_create(t) }
  end

  def keywords=(somewords="")
    if somewords.blank?
      self.terms.clear
    else
      self.terms = Chemistry::Term.from_list(somewords)
    end
  end

end