module Chemistry
  class VideosController < ApplicationController
    load_and_authorize_resource

    def index
      render json: @videos
    end
  
    def show
      return_video
    end
  
    def create
      if @video.update_attributes(video_params)
        return_video
      else
        return_errors
      end
    end

    def update
      if @video.update_attributes(video_params)
        return_video
      else
        return_errors
      end
    end
    
    def destroy
      @video.destroy
      head :no_content
    end

    def return_video
      render json: @video
    end

    def return_errors
      render json: { errors: @video.errors.to_a }, status: :unprocessable_entity
    end

    protected

    def video_params
      params.permit(
        :file,
        :file_name,
        :caption,
        :remote_url
      )
    end

  end
end