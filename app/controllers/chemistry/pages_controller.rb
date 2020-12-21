module Chemistry
  class PagesController < Chemistry::ApplicationController
    include Chemistry::Concerns::Searchable

    skip_before_action :authenticate_user!, only: [:home, :published, :latest, :archive, :children, :similar, :listed], raise: false
    load_and_authorize_resource :page_collection, class: Chemistry::PageCollection, only: [:new, :create, :edit]
    load_and_authorize_resource class: Chemistry::Page, except: [:home, :published, :latest, :children, :controls, :new, :archive], through: :page_collection, shallow: true

    ## Deliver page to public user
    #
    def home
      @page = Chemistry::Page.home.first
      if @page && @page.published?
        if stale?(etag: @page, last_modified: @page.published_at)
          render template: "chemistry/pages/published", layout: chemistry_layout
        end
      else
        render template: "chemistry/welcome", layout: "chemistry/application"
      end
    end

    def published
      @path = (params[:path] || '').sub(/\/$/, '').sub(/^\//, '').strip
      @page = Chemistry::Page.published_with_path(@path)
      Rails.logger.warn "🦋 published #{@path} -> #{@page}"
      if @page && (@page.public? || user_signed_in?)
        render layout: chemistry_layout
      else
        page_not_found
      end
    end

    def archive
      @params = archive_params
      @q = @params[:q]
      @pages = Chemistry::Page.search_and_aggregate(@params)
      render layout: chemistry_layout
    end


    # Welcome to empty site
    #
    def welcome
      render template: "chemistry/welcome", layout: "chemistry/application"
    end


    # New returns a tiny inline form that will create an empty page and forward to edit
    #
    def new
      @page = @page_collection.pages.build(new_page_params)
      render layout: false
    end

    def create
      @page = Chemistry::Page.new(new_page_params.merge(user_id: user_signed_in? && current_user.id))
      if @page.save
        redirect to edit_page_url(@page)
      else
        render action: "new", layout: false
      end
    end

    # Edit shows the SPA editor and the rest of the edit and save process goes through the API.
    #
    def edit
      render layout: chemistry_editing_layout
    end


    # Page fragments
    #
    # `latest` returns a list useful for populating sidebars and menus with 'latest update' type blocks
    # optional `parent` param contains a path string, scopes the list to children of the page at that path.
    #
    def latest
      limit = params[:limit].presence || 1
      @pages = Page.published.latest.limit(limit)
      if params[:parent] and @page = Chemistry::Page.where(path: params[:parent]).first
        @pages = @pages.with_parent(@page)
      end
      if @pages && @pages.any?
        render template: "chemistry/pages/toc", layout: false
      else
        head :no_content
      end
    end

    # `children` returns a toc list of published pages under the given page id.
    #
    def children
      if params[:page_id].present?
        @pages = Chemistry::Page.search(where: {parent: params[:page_id]}, load: false);
      end
      if @pages && @pages.any?
        render template: "chemistry/pages/toc", layout: false
      else
        head :no_content
      end
    end

    # `similar` returns a toc list of published pages under the given page id.
    #
    def similar
      @page = Chemistry::Page.find(params[:page_id])
      @pages = @page.similar_pages
      if @pages && @pages.any?
        render template: "chemistry/pages/toc", layout: false
      else
        head :no_content
      end
    end

    def listed
      if params[:page_ids].present?
        page_ids = params[:page_ids].split(',').map(&:to_i).compact.uniq
        @pages = Chemistry::Page.search(where: {id: page_ids}, load: false);
      end
      if @pages && @pages.any?
        render template: "chemistry/pages/toc", layout: false
      else
        head :no_content
      end
    end

    # Control block added to (cacheable) public page if user is signed in.
    #
    def controls
      if params[:path].present? && can?(:edit, Chemistry::Page)
        @page = Chemistry::Page.find_by(path: params[:path])
        render layout: false
      else
        head :no_content
      end
    end


    protected
  
    ## Error pages

    def page_not_found
      if @page = Chemistry::Page.published_with_path("/404")
        render layout: chemistry_layout
      else
        render template: "chemistry/pages/not_found", layout: chemistry_layout
      end
    end


    ## Permitted parameters
    #
    # New-page link can make basic preparations
    #
    def new_page_params
      if params[:page].present?
        params.require(:page).permit(
          :title,
          :private,
          :page_collection_id
        )
      else
        {}
      end
    end

    def archive_params
      params.permit(:page_collection, :page_category, :month, :date_from, :date_to, :q, :sort, :order, :show, :page, terms: [])
    end


    ## Searchable configuration
    #
    def search_class
      Chemistry::Page
    end

    def search_fields
      ['title^5', 'content', 'byline']
    end

    def search_highlights
      {tag: "<strong>"}
    end

    def search_default_sort
      "published_at"
    end

    # for the public archive page we facet using slug parameters for readability and consistency with urls
    def search_aggregations
      ['page_collection', 'page_category', 'terms']
    end

    def paginated?
      true
    end

    def search_load?
      false
    end

  end
end