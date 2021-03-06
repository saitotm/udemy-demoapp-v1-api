Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  namespace :api do
    namespace :v1 do
      resources :users, only:[:index] do
        get :current_user, action: :show, on: :collection
      end

      resources :user_token, only: [:create] do
        delete :destroy, on: :collection
      end
    end
  end
end
