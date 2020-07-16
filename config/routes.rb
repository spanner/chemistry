Chemistry::Engine.routes.draw do

  match "*all" => "application#cors_check", :via => :options, :constraints => {:method => 'OPTIONS'}

  root to: "pages#welcome", as: :welcome

  scope :api, defaults: { format: 'json' }, constraints: { format: 'json' } do
    resources :pages
    resources :page_collections
    resources :page_categories
    resources :images
    resources :videos
    resources :documents
  end

  scope defaults: { format: 'html' }, constraints: { format: 'html' } do
    get "/page_controls(/*path)" => "pages#controls", as: :page_controls
    get "latest/*parent" => "pages#latest"
    get "contents/*parent" => "pages#children", as: :contents
  end
end
