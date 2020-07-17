module Chemistry
  class PageCollectionsController < Chemistry::ApplicationController
    skip_before_action :authenticate_user!, only: [:index, :show, :archive, :latest], raise: false
    load_and_authorize_resource find_by: :slug


    # Public collection home page
    #
    def show
      render layout: Chemistry.public_layout
    end

    # Public Archive / search view
    #
    def archive
      @pages = @page_collection.search_and_aggregate_pages(archive_params)
      render layout: Chemistry.admin_layout
    end



    # Admin overview page
    #
    def dashboard
      @page_collections = PageCollection.order(:title)
      render layout: Chemistry.admin_layout
    end
  
    # Admin latest-updates page
    # nb. public home page is home#home
    #
    def index
      @page_collections = @page_collections.made_public
      render layout: Chemistry.admin_layout
    end

    # Admin page quick search
    #
    def filter
      @pages = @page_collection.latest_page_search_results
      render partial: "pages/filtered", layout: false
    end

    # Admin crud
    #
    def edit
      render layout: Chemistry.admin_layout
    end
  
    def update
      if @page_collection.update_attributes(page_collection_params)
        redirect_to page_collection_url(@page_collection)
      else
        render action: :edit
      end
    end

    def new
      render layout: Chemistry.admin_layout
    end
  
    def create
      if @page_collection.update_attributes(page_collection_params)
        redirect_to page_collection_url(@page_collection)
      else
        render action: :new
      end
    end


    private

    def archive_params
      params.permit(:page_collection_id, :page_category_id, :month, :term, :q, :sort, :order, :show, :page)
    end

    def page_collection_params
      if params[:page_collection]
        params.require(:page_collection).permit(:title, :short_title, :slug, :introduction, :cobrand, :public)
      end
    end

  end
end