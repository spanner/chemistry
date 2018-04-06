module Chemistry
  class TermSynonym < ActiveRecord::Base
    belongs_to :term
  end
end