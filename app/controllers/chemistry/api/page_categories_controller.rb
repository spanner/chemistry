module Chemistry::Api
  class PageCategoriesController < Chemistry::Api::ApiController
    load_and_authorize_resource class: Chemistry::PageCategory

    def index
      return_page_categories
    end

    def show
      return_page_category
    end

    def create
      if @page_category.update_attributes(page_category_params)
        return_page_category
      else
        return_errors
      end
    end

    def update
      if @page_category.update_attributes(page_category_params)
        return_page_category
      else
        return_errors
      end
    end


    protected

    def return_page_categories
      render json: Chemistry::PageCategorySerializer.new(@page_categories).serialized_json
    end

    def return_page_category
      render json: Chemistry::PageCategorySerializer.new(@page_category).serialized_json
    end

    def return_errors
      render json: { errors: @page_category.errors.to_a }, status: :unprocessable_entity
    end

    def page_category_params
      if params[:page_category]
        params.require(:page_category).permit(:title, :slug, :introduction)
      end
    end

  end
end