module Chemistry::Api
  class PageCollectionsController < Chemistry::Api::ApiController
    load_and_authorize_resource class: Chemistry::PageCollection

    def index
      @page_collections = @page_collections.order(title: :asc)
      return_page_collections
    end

    def show
      return_page_collection
    end

    def create
      if @page_collection.update(page_collection_params)
        return_page_collection
      else
        return_errors
      end
    end

    def update
      if @page_collection.update(page_collection_params)
        return_page_collection
      else
        return_errors
      end
    end


    protected

    def return_page_collections
      render json: Chemistry::PageCollectionSerializer.new(@page_collections).serializable_hash.as_json
    end

    def return_page_collection
      render json: Chemistry::PageCollectionSerializer.new(@page_collection).serializable_hash.as_json
    end

    def return_errors
      render json: { errors: @page_collection.errors.to_a }, status: :unprocessable_entity
    end

    def page_collection_params
      if params[:page_collection]
        params.require(:page_collection).permit(:title, :short_title, :slug, :introduction, :private)
      end
    end

  end
end