module Chemistry
  class PageTerm < ActiveRecord::Base
    belongs_to :term
    belongs_to :page
  end
end