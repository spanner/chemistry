Chemistry::Engine.routes.draw do

  match "*all" => "application#cors_check", :via => :options, :constraints => {:method => 'OPTIONS'}

  root to: "pages#editor"

  resources :pages do
    resources :sections
    get :site, on: :collection
    put :publish, on: :member
    get :publshed, on: :member
  end

  resources :templates do
    resources :placeholders
  end

  resources :section_types
  resources :images
  resources :videos
  resources :documents

  get "*path" => "pages#editor"

end
