Chemistry::Engine.routes.draw do

  match "*all" => "application#cors_check", :via => :options, :constraints => {:method => 'OPTIONS'}

  root to: "pages#editor"

  resources :pages do
    put :publish, on: :member
  end

  resources :templates
  resources :images
  resources :videos
  resources :documents
  resources :section_types

end
