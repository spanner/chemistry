module Chemistry
  class ApplicationController < ::ApplicationController
    layout :chemistry_layout
    before_action :set_access_control_headers
    skip_before_action :verify_authenticity_token, raise: false

    def cors_check
      head :ok
    end

    def chemistry_layout
      Chemistry.config.public_layout
    end

    def chemistry_admin_layout
      Chemistry.config.admin_layout
    end

    def chemistry_editing_layout
      Chemistry.config.editing_layout || Chemistry.config.admin_layout
    end

    def chemistry_search_layout
      Chemistry.config.search_layout || Chemistry.config.public_layout
    end

    def paginated(collection, default_show=10, default_page=1)
      @show = (params[:show] || default_show).to_i
      @page = (params[:page] || default_page).to_i
      collection.page(@page).per(@show)
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

    def chemistry_controller?
      true
    end

    def no_layout_if_pjax
      if pjax?
        @pjax = true
        false
      else
        @pjax = false
        default_layout
      end
    end

    def default_layout
      chemistry_admin_layout
    end

    def pjax?
      request.headers['X-PJAX'].present?
    end
  end
end
