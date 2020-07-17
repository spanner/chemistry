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
      @page = Chemistry::Page.published.with_path(@path).first
      if @page && (@page.public? || user_signed_in?)
        render layout: Chemistry.public_layout
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
      render
    end

    def edit
      render
    end


    # Page fragments
    #
    # `latest` returns a list useful for populating sidebars and menus with 'latest update' type blocks
    # optional `parent` param contains a path string, scopes the list to children of the page at that path.
    #
    def latest
      limit = params[:limit].presence || 1
      @pages = Page.published.latest.limit(limit)
      if params[:parent] and @page = Page.where(path: params[:parent]).first
        @pages = @pages.with_parent(@page)
      end
      render layout: false
    end

    # `children` returns paginated lists of published pages under the given page path.
    # TODO: search index!
    #
    def children
      if @page = Page.where(path: params[:parent]).first
        @pages = @page.child_pages.published

        # sort
        @sort = params[:sort] if ["published_at", "date", "title"].include?(params[:sort])
        @sort ||= "published_at"
        @order = params[:order] || (@sort == 'title' ? "asc" : "desc")
        Rails.logger.warn "children: sort #{@sort}, order #{@order}: #{{@sort => @order}.inspect}"
        @pages = @pages.order(@sort => @order)

        # paginate
        @p = params[:p] || 1
        @pp = params[:limit] || Chemistry.default_per_page
        @pages = @pages.page(@p).per(@pp)
        render layout: false
      else
        head :no_content
      end
    end

    # Control block added to public page if user is signed in.
    #
    def controls
      if params[:path].present?
        @page = Chemistry::Page.find_by(path: params[:path])
      else
        @page = Chemistry::Page.home.first
      end
      if @page && can?(:edit, @page)
        render layout: false
      else
        head :no_content
      end
    end


    protected
  
    ## Error pages

    def page_not_found
      if @page = Page.published.with_path("/404").first
        render layout: Chemistry.public_layout
      else
        render template: "chemistry/pages/not_found", layout: Chemistry.public_layout
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

  end
end