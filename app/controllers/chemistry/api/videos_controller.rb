module Chemistry::Api
  class VideosController < Chemistry::Api::ApiController
    include Chemistry::Concerns::Searchable
    # load_and_authorize_resource class: Chemistry::Video, except: [:index]
    load_resource class: Chemistry::Video, except: [:index]

    def index
      return_videos
    end
  
    def show
      return_video
    end
  
    def create
      if @video.update_attributes(video_params.merge(user_id: user_signed_in? && current_user.id))
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


    ## Standard responses

    def return_videos
      render json: Chemistry::VideoSerializer.new(@videos).serialized_json
    end

    def return_video
      render json: Chemistry::VideoSerializer.new(@video).serialized_json
    end

    def return_errors
      render json: { errors: @video.errors.to_a }, status: :unprocessable_entity
    end


    protected

    def video_params
      params.require(:video).permit(
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
      Chemistry::Video
    end

    def search_fields
      ['title']
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

  end
end