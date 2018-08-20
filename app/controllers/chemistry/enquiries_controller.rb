module Chemistry
  class EnquiriesController < ApplicationController
    load_and_authorize_resource except: [:enquire]

    # This is mostly here to create a distinctive path that can be exempted from authentication
    # on the application side, without making any guesses here about how that would work.
    #
    def enquire
      @enquiry = Enquiry.new(enquiry_params)
      @enquiry.request = request
      if @enquiry.save
        return_enquiry
      else
        return_errors
      end
    end

    # API crud to support list / reply / close in UI
    #
    def index
      limit = params[:limit].presence || 10
      @enquiries = paginated(@enquiries, limit)
      return_enquiries
    end

    def show
      return_enquiry
    end

    def update
      @enquiry.update_attributes(enquiry_params)
      return_enquiry
    end

    def destroy
      @enquiry.destroy
      head :no_content
    end


    ## Standard responses

    def return_enquiries
      render json: EnquirySerializer.new(@enquiries).serialized_json
    end

    def return_enquiry
      render json: EnquirySerializer.new(@enquiry).serialized_json
    end

    def return_errors
      render json: { errors: @enquiry.errors.to_a }, status: :unprocessable_entity
    end

  protected

    def enquiry_params
      params.require(:enquiry).permit(:name, :email, :message, :closed, :robot)
    end

  end
end