Rails.application.routes.draw do
  resources :children, only: [] do
    post :score, on: :member
  end
  
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root to: "static_page#home"
end
