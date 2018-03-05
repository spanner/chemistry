module Chemistry
  class ApplicationController < ::ApplicationController
    layout :chemistry_layout
    before_action :set_access_control_headers
    skip_before_action :verify_authenticity_token

    def cors_check
      set_access_control_headers
      head :ok
    end

    def chemistry_layout
      Chemistry.layout
    end

    def set_access_control_headers
      if request.env["HTTP_ORIGIN"].present?
        headers['Access-Control-Allow-Origin'] = request.env["HTTP_ORIGIN"]
        headers["Access-Control-Allow-Credentials"] = "true"
        headers["Access-Control-Allow-Methods"] = %{DELETE, GET, PATCH, POST, PUT}
        headers['Access-Control-Request-Method'] = '*'
        headers['Access-Control-Allow-Headers'] = 'Origin, X-PJAX, X-Requested-With, X-ClientID, Content-Type, Accept, Authorization'
      end
    end

  end
end
