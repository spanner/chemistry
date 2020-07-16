module Chemistry::API
  class ImagesController < Chemistry::Api::ApiController
    load_and_authorize_resource except: [:index]

    def index
      Rails.logger.warn "☀️ index"
      if current_user.respond_to?(:images)
        @images = current_user.images
      else
        @images = Image.all
      end
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
  
  end
end