require 'json'

module Chemistry::API
  class PagesController < Chemistry::Api::ApiController
    include Chemistry::Concerns::Searchable

    skip_before_action :authenticate_user!, only: [:published, :latest, :bundle], raise: false
    load_and_authorize_resource except: [:published, :latest, :children, :home, :bundle, :new]


    ## API routes
    # Support the editing UI and a few public functions like list pagination.
    #
    def index
      return_pages
    end

    def show
      return_page if stale?(etag: @page, last_modified: @page.published_at, public: true)
    end

    def create
      if @page.update_attributes(page_params)
        return_page
      else
        return_errors
      end
    end

    def update
      if @page.update_attributes(page_params)
        return_page
      else
        return_errors
      end
    end

    def publish
      if @page.publish!(publish_params)
        return_page
      else
        return_errors
      end
    end

    def destroy
      @page.destroy
      head :no_content
    end



    ## Standard API responses

    def return_pages
      render json: PageSerializer.new(@pages).serialized_json
    end

    def return_pages_with_everything
      render json: PublicPageSerializer.new(@pages, include: [:socials, :image, :video]).serialized_json
    end

    def return_page
      render json: PageSerializer.new(@page).serialized_json
    end

    def return_errors
      render json: { errors: @page.errors.to_a }, status: :unprocessable_entity
    end


    ## Error pages

    def page_not_found
      if @page = Page.published.with_path("/404").first
        render layout: Chemistry.public_layout
      else
        render template: "chemistry/pages/not_found", layout: Chemistry.public_layout
      end
    end


    protected
  
    ## Permitted parameters
    #
    # New-page link can set basic properties
    #
    def new_page_params
      params.permit(
        :slug,
        :private,
        :title
      )
    end
  
    def page_params
      params.require(:page).permit(
        :parent_id,
        :slug,
        :private,
        :style,
        :title,             # authoring page parts
        :content,           #
        :masthead,          #
        :excerpt,
        :nav,               # takes part in navigation?
        :nav_name,          # with this name
        :nav_position,      # in this position
        :terms
      )
    end

    def publish_params
      params.require(:page).permit(
        :published_title,
        :published_html,
        :published_excerpt
      )
    end

    ## Searchable configuration
    #
    def search_fields
      ['title^10', 'terms^5', 'content']
    end

    def search_highlights
      {tag: "<strong>"}
    end

    def search_default_sort
      "title"
    end

  end
end