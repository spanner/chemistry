Chemistry::Engine.routes.draw do

  match "*all" => "application#cors_check", :via => :options, :constraints => {:method => 'OPTIONS'}

  namespace :api, defaults: { format: 'json' }, constraints: { format: 'json' } do
    resources :pages do
      put :publish, on: :member
    end
    resources :page_collections, only: [:index, :show]
    resources :page_categories, only: [:index, :show]
    resources :images, only: [:index, :show, :create, :update]
    resources :videos, only: [:index, :show, :create, :update]
    resources :documents, only: [:index, :show, :create, :update]
  end

  resources :pages

  resources :page_collections do
    resources :pages
    member do
      get :archive
      get :filter
    end
    collection do
      get :dashboard
    end
  end

  scope defaults: { format: 'html' }, constraints: { format: 'html' } do
    get "page_controls(/*path)" => "pages#controls", as: :page_controls
    get "latest/*parent" => "pages#latest", as: :latest
    get "contents/:parent_id" => "pages#children", as: :contents
    get "toc/list/:page_ids" => "pages#listed", as: :listed_pages
    get "toc/children/:page_id" => "pages#children", as: :child_pages
    get "toc/similar/:page_id" => "pages#similar", as: :similar_pages
    get "/*path" => "pages#published", as: :published_page
  end
end
