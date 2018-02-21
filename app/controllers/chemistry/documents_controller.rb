module Chemistry
  class DocumentsController < ApplicationController
    load_and_authorize_resource

    def index
      render json: @documents
    end
  
    def show
      return_document
    end
  
    def create
      if @document.update_attributes(document_params)
        return_document
      else
        return_errors
      end
    end

    def update
      if @document.update_attributes(document_params)
        return_document
      else
        return_errors
      end
    end
    
    def destroy
      @document.destroy
      head :no_content
    end

    def return_document
      render json: @document
    end

    def return_errors
      render json: { errors: @document.errors.to_a }, status: :unprocessable_entity
    end

    protected

    def document_params
      params.permit(
        :file,
        :file_name,
        :page_id,
        :caption,
        :remote_url
      )
    end

  end
end