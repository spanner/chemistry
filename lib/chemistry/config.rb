module Chemistry
  class Config
    attr_accessor :public_layout,
                  :admin_layout,
                  :editing_layout,
                  :host,
                  :protocol,
                  :api_url,
                  :user_class,
                  :user_key,
                  :default_page_style,
                  :default_per_page,
                  :login_path,
                  :site_name,
                  :site_description,
                  :site_host,
                  :site_image_url


    @user_class = "User"
    @user_key = "id"
    @default_per_page = 10
    @default_page_style = 'illustrated'
    @site_host = "https://example.com"
    @site_name = "Chemistry"
    @site_description = "Another splendid website built with Chemistry"
  end
end