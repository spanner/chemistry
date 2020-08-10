module Chemistry
  class PageCollectionsController < Chemistry::ApplicationController
    skip_before_action :authenticate_user!, only: [:index, :show, :archive, :latest], raise: false
    load_resource class: Chemistry::PageCollection, find_by: :slug
    before_action :get_pages, only: [:show, :features]


    # Public collection home page
    #
    def show
      render layout: chemistry_layout
    end

    def features
      if stale?(etag: @pages, public: true)
        render partial: "chemistry/pages/feature", collection: @pages, layout: false
      end
    end

    # Public Archive / search view
    #
    def archive
      @params = archive_params.merge({page_collection: @page_collection.slug})
      @pages = Chemistry::Page.search_and_aggregate(@params)
      render layout: chemistry_admin_layout
    end

    # Admin overview page
    #
    def dashboard
      @page_collections = PageCollection.order(:title)
      render layout: chemistry_admin_layout
    end
  
    # Admin latest-updates page
    # nb. public home page is home#home
    #
    def index
      @page_collections = @page_collections.made_public
      render layout: chemistry_admin_layout
    end

    # Admin page quick search
    #
    def filter
      @pages = @page_collection.latest_page_search_results
      render partial: "page_collections/filtered", layout: false
    end

    # Admin crud
    #
    def edit
      render layout: chemistry_admin_layout
    end
  
    def update
      if @page_collection.update_attributes(page_collection_params)
        redirect_to page_collection_url(@page_collection)
      else
        render action: :edit
      end
    end

    def new
      render layout: chemistry_admin_layout
    end
  
    def create
      if @page_collection.update_attributes(page_collection_params)
        redirect_to page_collection_url(@page_collection)
      else
        render action: :new
      end
    end


    private

    def get_pages
      @p = params[:p] || 1
      @pp = 14
      @pages = Chemistry::Page.search "*", where: {published: true, page_collection: @page_collection.slug}, order: {published_at: :desc}, load: false, per_page: @pp, page: @p
    end

    def archive_params
      params.permit(:page_collection, :page_category, :month, :date_from, :date_to, :q, :sort, :order, :show, :page, terms: [])
    end

    def page_collection_params
      if params[:page_collection]
        params.require(:page_collection).permit(:title, :short_title, :slug, :introduction, :cobrand, :featured, :private, :eventful)
      else
        {}
      end
    end

  end
end