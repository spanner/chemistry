module Chemistry::Api
  class ImagesController < Chemistry::Api::ApiController
    include Chemistry::Concerns::Searchable
    load_and_authorize_resource class: Chemistry::Image, except: [:index]

    def index
      return_images
    end

    def show
      return_image
    end

    def create
      if @image.update(image_params.merge(user_id: user_signed_in? && current_user.id))
        return_image
      else
        return_errors
      end
    end

    def update
      if @image.update(image_params)
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
      render json: Chemistry::ImageSerializer.new(@images).serializable_hash.as_json
    end

    def return_image
      render json: Chemistry::ImageSerializer.new(@image).serializable_hash.as_json
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
    def search_class
      Chemistry::Image
    end

    def search_fields
      ['title', 'file_name']
    end

    def search_match
      :word_start
    end

    def search_highlights
      {tag: "<strong>"}
    end

    def search_default_sort
      "created_at"
    end

  def default_per_page
    50
  end

  end
end