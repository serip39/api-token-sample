Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root 'home#index'
  namespace :api do
    namespace :v1 do
      get '/whoami', to: 'tests#whoami'
    end
  end

  scope :api do
    scope :v1 do
      # device_token_auth
      mount_devise_token_auth_for 'User', at: 'auth', controllers: {
        sessions: 'custom/sessions',
      }
      devise_scope :auth do
        post '/auth/sign_up', to: 'devise_token_auth/registrations#create'
      end
    end
  end
end
