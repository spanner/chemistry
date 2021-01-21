module Chemistry::Api
  class DocumentsController < Chemistry::Api::ApiController
    include Chemistry::Concerns::Searchable
    load_and_authorize_resource class: Chemistry::Document, except: [:index]

    def index
      return_documents
    end

    def show
      return_document
    end

    def create
      if @document.update(document_params.merge(user_id: user_signed_in? && current_user.id))
        return_document
      else
        return_errors
      end
    end

    def update
      if @document.update(document_params)
        return_document
      else
        return_errors
      end
    end

    def destroy
      @document.destroy
      head :no_content
    end


    ## Standard responses

    def return_documents
      render json: Chemistry::DocumentSerializer.new(@documents).serializable_hash.as_json
    end

    def return_document
      render json: Chemistry::DocumentSerializer.new(@document).serializable_hash.as_json
    end

    def return_errors
      render json: { errors: @document.errors.to_a }, status: :unprocessable_entity
    end


    protected

    def document_params
      params.require(:document).permit(
        :file_data,
        :file_name,
        :caption,
        :remote_url
      )
    end

    ## Searchable configuration
    #
    def search_class
      Chemistry::Document
    end

    def search_fields
      ['title', 'file_name']
    end

    def search_match
      :word_middle
    end

    def search_highlights
      {tag: "<strong>"}
    end

    def search_default_sort
      "created_at"
    end

  end
end