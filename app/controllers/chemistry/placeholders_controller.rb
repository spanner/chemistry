module Chemistry
  class PlaceholdersController < ApplicationController
    load_and_authorize_resource

    def index
      return_placeholders
    end
  
    def show
      return_placeholder
    end
  
    def create
      if @placeholder.update_attributes(placeholder_params)
        return_placeholder
      else
        return_errors
      end
    end

    def update
      if @placeholder.update_attributes(placeholder_params)
        return_placeholder
      else
        return_errors
      end
    end
    
    def destroy
      @placeholder.destroy
      head :no_content
    end


    ## Standard responses

    def return_placeholders
      render json: PlaceholderSerializer.new(@placeholders).serialized_json
    end

    def return_placeholder
      render json: PlaceholderSerializer.new(@placeholder).serialized_json
    end

    def return_errors
      render json: { errors: @placeholder.errors.to_a }, status: :unprocessable_entity
    end


    protected

    def placeholder_params
      params.permit(
        :template_id,
        :position,
        :section_type_id,
        :title,
        :primary_html,
        :secondary_html
      )
    end

  end
end