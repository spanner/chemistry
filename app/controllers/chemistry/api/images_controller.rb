module Chemistry::Api
  class ImagesController < Chemistry::Api::ApiController
    include Chemistry::Concerns::Searchable
    load_and_authorize_resource except: [:index]

    def index
      return_images
    end

    def show
      return_image
    end

    def create
      if @image.update_attributes(image_params.merge(user_id: current_user.id))
        return_image
      else
        return_errors
      end
    end

    def update
      if @image.update_attributes(image_params)
        return_image
      else
        return_errors
      end
    end
    
    def destroy
      @image.destroy
      head :no_content
    end


    ## Standard responses

    def return_images
      render json: ImageSerializer.new(@images).serialized_json
    end

    def return_image
      render json: ImageSerializer.new(@image).serialized_json
    end

    def return_errors
      render json: { errors: @image.errors.to_a }, status: :unprocessable_entity
    end


    protected

    def image_params
      params.require(:image).permit(
        :file_data,
        :file_name,
        :file_type,
        :caption,
        :remote_url
      )
    end

    ## Searchable configuration
    #
    def search_fields
      ['title']
    end

    def search_highlights
      {tag: "<strong>"}
    end

    def search_default_sort
      "created_at"
    end

  end
end