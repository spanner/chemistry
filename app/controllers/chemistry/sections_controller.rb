module Chemistry
  class SectionsController < ApplicationController
    load_and_authorize_resource :page
    load_and_authorize_resource through: :page

    def index
      return_sections
    end
  
    def show
      return_section
    end
  
    def create
      if @section.update_attributes(section_params)
        return_section
      else
        return_errors
      end
    end

    def update
      if @section.update_attributes(section_params)
        return_section
      else
        return_errors
      end
    end
    
    def destroy
      @section.destroy
      head :no_content
    end


    ## Standard responses

    def return_sections
      render json: SectionSerializer.new(@sections).serialized_json
    end

    def return_section
      render json: SectionSerializer.new(@section).serialized_json
    end

    def return_errors
      render json: { errors: @section.errors.to_a }, status: :unprocessable_entity
    end


    protected

    def section_params
      params.permit(
        :position,
        :section_type_id,
        :title,
        :primary_html,
        :secondary_html
      )
    end

  end
end