module Chemistry
  class PageCategoriesController < Chemistry::ApplicationController
    skip_before_action :authenticate_user!, only: [:index, :show, :archive, :latest], raise: false
    load_resource class: Chemistry::PageCategory, find_by: :slug, except: [:edit, :update]
    load_resource class: Chemistry::PageCategory, only: [:edit, :update]
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
      @params = archive_params.merge({page_category: @page_category.slug})
      @pages = Chemistry::Page.search_and_aggregate(@params)
      render layout: chemistry_admin_layout
    end

    # Admin overview page
    #
    def dashboard
      @page_categories = PageCollection.order(title: :asc)
      render layout: chemistry_admin_layout
    end
  
    # Admin latest-updates page
    # nb. public home page is home#home
    #
    def index
      @page_categories = Chemistry::PageCategory.order(title: :asc)
      render layout: chemistry_admin_layout
    end

    # Admin page quick search
    #
    def filter
      @pages = @page_category.latest_page_search_results
      render partial: "chemistry/page_categories/filtered", layout: false
    end

    # Admin crud
    #
    def edit
      render layout: chemistry_admin_layout
    end
  
    def update
      if @page_category.update(page_category_params)
        redirect_to page_category_home_url(@page_category.slug)
      else
        render action: :edit
      end
    end

    def new
      render layout: chemistry_admin_layout
    end
  
    def create
      if @page_category.update(page_category_params)
        redirect_to page_category_home_url(@page_category)
      else
        render action: :new
      end
    end


    private

    def get_pages
      @p = params[:p] || 1
      @pp = 14
      @pages = Chemistry::Page.search "*", where: {published: true, page_category: @page_category.slug}, order: {published_at: :desc}, load: false, per_page: @pp, page: @p
    end

    def archive_params
      params.permit(:page_category, :page_category, :month, :date_from, :date_to, :q, :sort, :order, :show, :page, terms: [])
    end

    def page_category_params
      if params[:page_category]
        params.require(:page_category).permit(:title, :short_title, :slug, :introduction, :cobrand, :featured, :private, :eventful)
      else
        {}
      end
    end

  end
end