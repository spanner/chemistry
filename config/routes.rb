Chemistry::Engine.routes.draw do

  match "*all" => "application#cors_check", :via => :options, :constraints => {:method => 'OPTIONS'}

  root to: "pages#welcome", as: :welcome

  scope :api, defaults: { format: 'json' }, constraints: { format: 'json' } do
    resources :pages do
      resources :sections
      get :latest, on: :collection
      get :site, on: :collection
    end

    resources :templates do
      resources :placeholders
    end

    resources :section_types
    resources :images
    resources :videos
    resources :documents
    resources :terms

    resources :enquiries do
      post :enquire, on: :collection
    end
  end

  scope defaults: { format: 'html' }, constraints: { format: 'html' } do
    get "editor" => "pages#editor", as: :editor
    get "latest/*parent" => "pages#latest"
    get "contents/*parent" => "pages#children"
    get "*path" => "pages#editor"
  end
end
