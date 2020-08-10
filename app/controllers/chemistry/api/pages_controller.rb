require 'json'

module Chemistry::Api
  class PagesController < Chemistry::Api::ApiController
    include Chemistry::Concerns::Searchable
    load_and_authorize_resource class: Chemistry::Page, except: [:index]

    ## API routes
    # Support the editing UI
    #
    def index
      return_pages
    end

    def show
      return_page if stale?(etag: @page, last_modified: @page.published_at, public: true)
    end

    def create
      page_attributes = page_params
      if (user_signed_in?) 
        page_attributes[:user_id] = current_user.id
      end
      if @page.update(page_attributes)
        return_page
      else
        return_errors
      end
    end

    def update
      if @page.update(page_params)
        return_page
      else
        return_errors
      end
    end

    def publish
      if @page.publish!
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
      render json: Chemistry::TreePageSerializer.new(@pages).serialized_json
    end

    def return_page
      render json: Chemistry::PageSerializer.new(@page).serialized_json
    end

    def return_errors
      render json: { errors: @page.errors.to_a }, status: :unprocessable_entity
    end


    ## Error pages

    def page_not_found
      head :not_found
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
        :slug,
        :private,
        :style,
        :title,
        :masthead,
        :content,
        :byline,
        :summary,
        :excerpt,
        :nav,               # takes part in navigation?
        :nav_name,          # with this name
        :nav_position,      # in this position
        :terms,
        :private,
        :parent_id,
        :page_collection_id,
        :page_category_id,
        :image_id
      )
    end

    ## Searchable configuration
    #
    def search_class
      Chemistry::Page
    end

    def search_fields
      ['title^10', 'path^5', 'terms^2', 'summary^2', 'content', 'byline']
    end

    def search_highlights
      {tag: "<strong>"}
    end

    def search_default_sort
      "created_at"
    end

    def search_aggregations
      ['page_collection', 'page_category', 'parent']
    end

    def paginated?
      true
    end

    def search_load?
      false
    end

  end
end