module Chemistry
  class Config
    attr_accessor :public_layout,
                  :admin_layout,
                  :host,
                  :protocol,
                  :api_url,
                  :user_class,
                  :user_key,
                  :default_per_page

    # defaults
    @user_class = "User"
    @user_key = "id"
    @default_per_page = 10

  end
end