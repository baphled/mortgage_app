Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :mortgage_applications, only: [:create, :show] do
        post :affordability_assessment, on: :member
      end
      
    end
  end
end
