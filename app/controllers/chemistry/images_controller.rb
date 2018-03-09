module Chemistry
  class ImagesController < ApplicationController
    load_and_authorize_resource

    def index
      return_images
    end
  
    def show
      return_image
    end
  
    def create
      if @image.update_attributes(image_params)
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

    def return_images {
      render json: ImageSerializer.new(@images)
    }

    def return_image
      render json: ImageSerializer.new(@image)
    end

    def return_errors
      render json: { errors: @image.errors.to_a }, status: :unprocessable_entity
    end


    protected

    def image_params
      params.permit(
        :file,
        :file_name,
        :caption,
        :remote_url
      )
    end
  
  end
end