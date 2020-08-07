module Chemistry
  class Config
    attr_accessor :public_layout,
                  :admin_layout,
                  :host,
                  :protocol,
                  :api_url,
                  :user_class,
                  :user_key,
                  :default_page_style,
                  :default_per_page,
                  :login_path

    # defaults
    @user_class = "User"
    @user_key = "id"
    @default_per_page = 10
    @default_page_style = 'illustrated'

  end
end