module Chemistry::Api
  class SocialsController < Chemistry::Api::ApiController
    load_and_authorize_resource :page
    load_and_authorize_resource through: :page

    def index
      return_socials
    end

    def show
      return_social
    end

    def create
      if @social.update(social_params)
        return_social
      else
        return_errors
      end
    end

    def update
      if @social.update(social_params)
        return_social
      else
        return_errors
      end
    end
    
    def destroy
      @social.destroy
      head :no_content
    end


    ## Standard responses

    def return_socials
      render json: SocialSerializer.new(@socials).serializable_hash.as_json
    end

    def return_social
      render json: SocialSerializer.new(@social).serializable_hash.as_json
    end

    def return_errors
      render json: { errors: @social.errors.to_a }, status: :unprocessable_entity
    end


    protected

    def social_params
      params.require(:social).permit(
        :page_id,
        :position,
        :platform,
        :name,
        :url
      )
    end

  end
end
