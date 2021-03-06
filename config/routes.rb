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
      get :filter
      get :features
    end
    collection do
      get :dashboard
    end
  end

  scope defaults: { format: 'html' }, constraints: { format: 'html' } do
    get "/parts/controls/*path" => "pages#controls", as: :page_controls
    get "/parts/collection_controls/:slug" => "page_collections#controls", as: :page_collection_controls

    get "toc/list/:page_ids" => "pages#listed", as: :listed_pages
    get "toc/children/:page_id" => "pages#children", as: :child_pages
    get "toc/similar/:page_id" => "pages#similar", as: :similar_pages
    get "collections/:id" => "page_collections#show", as: :page_collection_home

    get "collections/:id/features" => "page_collections#features", as: 'page_collection_features'
    get "collections/:id/features/:p" => "page_collections#features", as: 'more_page_collection_features'

    get "/archive/:page_collection" => "pages#archive", as: 'page_collection_archive'
    get "archive" => "pages#archive", as: 'archive'

    get "/*path" => "pages#published", as: :published_page
  end
end
