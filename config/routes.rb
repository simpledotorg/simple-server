Rails.application.routes.draw do
  devise_scope :admin do
    authenticated :admin do
      root to: "organizations#index", as: :admin_root
    end

    unauthenticated :admin do
      root to: "devise/sessions#new"
    end
  end

  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'

  namespace :api, defaults: { format: 'json' } do
    namespace :v1 do
      get 'ping', to: 'pings#show'
      post 'login', to: 'logins#login_user'

      scope :users do
        get 'find', to: 'users#find'
        post 'register', to: 'users#register'
        post '/:id/request_otp', to: 'users#request_otp'
        post '/me/reset_password', to: 'users#reset_password'
      end

      scope '/patients' do
        get 'sync', to: 'patients#sync_to_user'
        post 'sync', to: 'patients#sync_from_user'
      end

      scope '/blood_pressures' do
        get 'sync', to: 'blood_pressures#sync_to_user'
        post 'sync', to: 'blood_pressures#sync_from_user'
      end

      scope '/prescription_drugs' do
        get 'sync', to: 'prescription_drugs#sync_to_user'
        post 'sync', to: 'prescription_drugs#sync_from_user'
      end

      scope '/facilities' do
        get 'sync', to: 'facilities#sync_to_user'
      end

      scope '/protocols' do
        get 'sync', to: 'protocols#sync_to_user'
      end

      scope '/appointments' do
        get 'sync', to: 'appointments#sync_to_user'
        post 'sync', to: 'appointments#sync_from_user'
      end

      scope '/communications' do
        get 'sync', to: 'communications#sync_to_user'
        post 'sync', to: 'communications#sync_from_user'
      end

      scope '/medical_histories' do
        get 'sync', to: 'medical_histories#sync_to_user'
        post 'sync', to: 'medical_histories#sync_from_user'
      end
    end

    namespace :current, path: 'v2' do
      get 'ping', to: 'pings#show'
      post 'login', to: 'logins#login_user'

      scope :users do
        get 'find', to: 'users#find'
        post 'register', to: 'users#register'
        post '/:id/request_otp', to: 'users#request_otp'
        post '/me/reset_password', to: 'users#reset_password'
      end

      scope '/patients' do
        get 'sync', to: 'patients#sync_to_user'
        post 'sync', to: 'patients#sync_from_user'
      end

      scope '/blood_pressures' do
        get 'sync', to: 'blood_pressures#sync_to_user'
        post 'sync', to: 'blood_pressures#sync_from_user'
      end

      scope '/prescription_drugs' do
        get 'sync', to: 'prescription_drugs#sync_to_user'
        post 'sync', to: 'prescription_drugs#sync_from_user'
      end

      scope '/facilities' do
        get 'sync', to: 'facilities#sync_to_user'
      end

      scope '/protocols' do
        get 'sync', to: 'protocols#sync_to_user'
      end

      scope '/appointments' do
        get 'sync', to: 'appointments#sync_to_user'
        post 'sync', to: 'appointments#sync_from_user'
      end

      scope '/communications' do
        get 'sync', to: 'communications#sync_to_user'
        post 'sync', to: 'communications#sync_from_user'
      end

      scope '/medical_histories' do
        get 'sync', to: 'medical_histories#sync_to_user'
        post 'sync', to: 'medical_histories#sync_from_user'
      end

      if FeatureToggle.enabled?('USER_ANALYTICS')
        namespace :analytics do
          resource :user_analytics, only: [:show]
        end
      end
    end
  end

  devise_for :admins, controllers: { invitations: 'admins/invitations' }
  resources :admins

  resources :organizations, only: [:index] do
    resources :facility_groups, only: [:index, :show] do
      get :graphics

      resources :facilities, only: [:index, :show] do
        get :graphics
      end
    end
  end

  get "admin", to: redirect("/")

  namespace :admin do
    resources :audit_logs, only: [:index, :show]
    resources :organizations do
      resources :facility_groups
    end
    resources :facilities

    resources :protocols do
      resources :protocol_drugs
    end

    resources :users do
      put 'reset_otp', to: 'users#reset_otp'
      put 'disable_access', to: 'users#disable_access'
      put 'enable_access', to: 'users#enable_access'
    end
  end

  if FeatureToggle.enabled?('PURGE_ENDPOINT_FOR_QA')
    namespace :qa do
      delete 'purge', to: 'purges#purge_patient_data'
    end
  end
end
