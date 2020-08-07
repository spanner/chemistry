require 'json'

module Chemistry
  class PagesController < Chemistry::ApplicationController
    include Chemistry::Concerns::Searchable

    skip_before_action :authenticate_user!, only: [:published, :latest], raise: false
    load_resource :page_collection, only: [:new, :edit]
    load_resource except: [:published, :latest, :children, :controls, :new], through: :page_collection, shallow: true


    ## Deliver page to public user
    #
    def published
      Rails.logger.warn "🦋 published #{params[:path]}"
      @path = (params[:path] || '').sub(/\/$/, '').sub(/^\//, '').strip
      @page = Chemistry::Page.published_with_path(@path)
      if @page && (@page.public? || user_signed_in?)
        render layout: chemistry_layout
      else
        page_not_found
      end
    end


    # Welcome to empty site
    #
    def welcome
      render template: "chemistry/welcome", layout: "chemistry/application"
    end


    # New and edit bring up the SPA editor.
    #
    def new
      @page = Chemistry::Page.new(new_page_params)
      render layout: chemistry_admin_layout
    end

    def edit
      render layout: chemistry_admin_layout
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

    # Control block added to public page if user is signed in.
    #
    def controls
      @page = Chemistry::Page.find(params[:id])
      if @page# && can?(:edit, @page)
        render layout: false
      else
        head :no_content
      end
    end


    protected
  
    ## Error pages

    def page_not_found
      if @page = Chemistry::Page.published_with_path("/404").first
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
      params.permit(
        :path,
        :private,
        :title,
        :page_collection_id
      )
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