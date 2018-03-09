module Chemistry
  class TemplatesController < ApplicationController
    load_and_authorize_resource

    def index
      return_templates
    end

    def show
      return_template
    end

    def create
      if @template.update_attributes(template_params)
        return_template
      else
        return_errors
      end
    end

    def update
      if @template.update_attributes(template_params)
        return_template
      else
        return_errors
      end
    end
    
    def destroy
      @template.destroy
      head :no_content
    end


    ## Standard responses

    def return_templates {
      render json: TemplateSerializer.new(@templates)
    }

    def return_template {
      render json: TemplateSerializer.new(@template, include: [:placeholders])
    }

    def return_errors
      render json: { errors: @template.errors.to_a }, status: :unprocessable_entity
    end


    protected

    def template_params
      params.permit(
        :id,
        :title,
        placeholders: [
          :id,
          :position,
          :title,
          :slug,
          :main,
          :aside,
          :section_type_id
        ]
      )
    end

  end
end