Rails.application.routes.draw do
  resources :jobs, only: [] do
    collection do
      post :no_op
      post :exploding
    end
  end

  get :home, to: "static_page#home", as: :home_page
  
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root to: "static_page#home"
end
