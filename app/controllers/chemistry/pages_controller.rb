module Chemistry
  class PagesController < ApplicationController
    load_and_authorize_resource

    def index
      render json: @pages
    end

    def show
      return_page
    end

    def create
      if @page.update_attributes(create_page_params)
        return_page
      else
        return_errors
      end
    end

    def update
      if @page.update_attributes(update_page_params)
        return_page
      else
        return_errors
      end
    end
  
    def publish
      if @page.update_attributes(publish_page_params)
        @page.publish!
        return_page
      else
        return_errors
      end
    end
  
    def destroy
      @page.destroy
      head :no_content
    end

    def return_page {
      render json: @page
    }

    def return_errors
      render json: { errors: @page.errors.to_a }, status: :unprocessable_entity
    end


    protected
  
    def create_page_params
      params.permit(
        :template_id,
        :path,
        :title
      )
    end
  
    def update_page_params
      params.permit(
        :id,
        :template_id,
        :path,
        :title,
        :nav,               # takes part in navigation?
        :nav_name,          # with this name
        :nav_position,      # in this position
        sections: [
          :id,
          :position,
          :title,
          :main,
          :aside,
          :section_type_id,
          :image_id,
          :video_id,
          :document_id,
          :deleted_at
        ]
      )
    end

    def publish_page_params
      params.permit(
        :rendered_html
      )
    end

  end
end