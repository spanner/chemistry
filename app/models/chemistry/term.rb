module Chemistry
  class Term < ApplicationRecord

    belongs_to :parent, class_name: "Chemistry::Term", optional: true
    has_many :term_synonyms, dependent: :destroy
    has_many :page_terms, dependent: :destroy
    has_many :pages, through: :page_terms

    scope :other_than, -> term {
      where.not(term: term)
    }

    def self.find_or_create(term)
      if term.present?
        where(term: term.strip.downcase).first_or_create
      end
    end

    def self.from_list(list=[], or_create=true)
      list = list.split(/[,;]\s*/) if String === list
      list.uniq.map { |t| find_or_create(t) }
    end

    def self.for_selection(except_term=nil)
      terms = self.order(term: :asc)
      terms = terms.other_than(except_term) if except_term
      options = terms.map{|t| [t.term, t.id] }
      options.unshift(['', ''])
      options
    end

    ## Elasticsearch indexing
    #
    searchkick word_start: [:term, :synonyms]
    scope :search_import, -> { includes(:term_synonyms) }

    def search_data
      {
        term: term,
        synonyms: synonyms
      }
    end

    def synonyms
      term_synonyms.pluck(:synonym).uniq
    end

    def with_synonyms
      [term] + synonyms
    end

    def subsume(other_term=nil)
      if other_term && other_term != self
        self.activities << other_term.activities
        self.term_synonyms.create(synonym: other_term.term)
        self.save
        other_term.destroy
      end
    end
  end
end