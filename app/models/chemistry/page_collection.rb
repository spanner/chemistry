module Chemistry
  class PageCollection < ApplicationRecord
    include Concerns::Slugged
    acts_as_list
    has_many :pages

    validates :title, presence: true

    default_scope -> { order(:position) }
    scope :made_public, -> { where(private: false) }
    scope :made_private, -> { where(private: true) }

    def self.for_selection
      order(:short_title).map{|coll| [coll.short_title, coll.id] }
    end
  
    def self.facet_labels
      all.each_with_object({}) do |pc, h|
        h[pc.slug] = pc.short_title
      end
    end
  
    def empty?
      pages.empty?
    end
  
    def unpublished_pages
      pages.unpublished
    end

    def search_and_aggregate_pages(params={})
      Page.search_and_aggregate(params.merge({page_collection: id}))
    end

    def latest_page_search_results(params={})
      Page.search_and_aggregate({
        page_collection: slug,
        sort: :created_at,
        order: :desc,
        q: params[:q].presence,
        page: params[:page].presence || 1,
        show: params[:show].presence || 5
      })
    end

    def absolute_path
      "/#{slug}"
    end

  end
end
