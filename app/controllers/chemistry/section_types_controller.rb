module Chemistry
  class SectionTypesController < ApplicationController
    load_and_authorize_resource

    def index
      render json: @section_types
    end
  
    def show
      return_section_type
    end
  
    def create
      if @section_type.update_attributes(section_type_params)
        return_section_type
      else
        return_errors
      end
    end

    def update
      if @section_type.update_attributes(section_type_params)
        return_section_type
      else
        return_errors
      end
    end
    
    def destroy
      @section_type.destroy
      head :no_content
    end

    def return_section_type
      render json: @section_type
    end

    def return_errors
      render json: { errors: @section_type.errors.to_a }, status: :unprocessable_entity
    end

    protected

    def section_type_params
      params.permit(
        :title,
        :slug,
        :description,
        :template,
        :image,
        :image_name,
        :icon,
        :icon_name
      )
    end

  end
end