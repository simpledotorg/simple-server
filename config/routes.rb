Rails.application.routes.draw do
  devise_scope :email_authentication do
    authenticated :email_authentication, ->(a) { a.user.has_role?(:counsellor) } do
      root to: "patients#index", as: :counsellor_root
    end

    authenticated :email_authentication do
      root to: "organizations#index", as: :email_authentication_root
    end

    unauthenticated :email_authentication do
      root to: "devise/sessions#new"
    end
  end

  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'

  concern :sync_routes do
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

    scope '/medical_histories' do
      get 'sync', to: 'medical_histories#sync_to_user'
      post 'sync', to: 'medical_histories#sync_from_user'
    end
  end

  namespace :api, defaults: { format: 'json' } do

    # Returning HTTP Status `410` for deprecated API version `v1`
    namespace :v1 do
      match '*all', via: [:get, :post, :put, :delete, :patch], to: proc { [410, {}, ['']] }
    end

    namespace :v2 do
      get 'ping', to: 'pings#show'
      post 'login', to: 'logins#login_user'

      if FeatureToggle.enabled?('PHONE_NUMBER_MASKING')
        # Exotel requires all endpoints to be GET
        scope :exotel_call_sessions do
          get 'fetch', to: 'exotel_call_sessions#fetch'
          get 'create', to: 'exotel_call_sessions#create'
          get 'terminate', to: 'exotel_call_sessions#terminate'
        end
      end

      scope :users do
        get 'find', to: 'users#find'
        post 'register', to: 'users#register'
        post '/:id/request_otp', to: 'users#request_otp'
        post '/me/reset_password', to: 'users#reset_password'
      end

      scope '/communications' do
        get 'sync', to: 'communications#sync_to_user'
        post 'sync', to: 'communications#sync_from_user'
      end

      concerns :sync_routes

      resource :help, only: [:show], controller: "help"

      if FeatureToggle.enabled?('USER_ANALYTICS')
        namespace :analytics do
          resource :user_analytics, only: [:show]
        end
      end
    end

    if FeatureToggle.enabled?('API_V3')
      namespace :current, path: 'v3' do
        get 'ping', to: 'pings#show'
        post 'login', to: 'logins#login_user'

        if FeatureToggle.enabled?('PHONE_NUMBER_MASKING')
          # Exotel requires all endpoints to be GET
          scope :exotel_call_sessions do
            get 'fetch', to: 'exotel_call_sessions#fetch'
            get 'create', to: 'exotel_call_sessions#create'
            get 'terminate', to: 'exotel_call_sessions#terminate'
          end
        end

        if FeatureToggle.enabled?('SMS_REMINDERS')
          resource :twilio_sms_delivery, only: [:create], controller: :twilio_sms_delivery
        end

        scope :users do
          get 'find', to: 'users#find'
          post 'register', to: 'users#register'
          post '/:id/request_otp', to: 'users#request_otp'
          post '/me/reset_password', to: 'users#reset_password'
        end

        concerns :sync_routes

        resource :help, only: [:show], controller: "help"

        if FeatureToggle.enabled?('USER_ANALYTICS')
          namespace :analytics do
            resource :user_analytics, only: [:show]
          end
        end
      end
    end
  end

  # devise_for :email_authentications, controllers: { invitations: 'email_authentications/invitations' }
  devise_for :email_authentications, path: 'email_authentications', controllers: { invitations: 'email_authentications/invitations' }
  resources :admins

  namespace :analytics do
    resources :facilities, only: [:show] do
      get 'share', to: 'facilities#share_anonymized_data'
      get 'graphics', to: 'facilities#whatsapp_graphics'
    end

    resources :organizations do
      resources :districts, only: [:show] do
        get 'share', to: 'districts#share_anonymized_data'
        get 'graphics', to: 'districts#whatsapp_graphics'
      end
    end
  end

  if FeatureToggle.enabled?('PATIENT_FOLLOWUPS')
    resources :appointments, only: [:index, :update]
    resources :patients, only: [:index, :update]
  end

  get "admin", to: redirect("/")

  namespace :admin do
    resources :audit_logs, only: [:index, :show]

    resources :organizations

    resources :facilities, only: [:index] do
      collection do
        get 'upload'
        post 'upload'
      end
    end
    resources :facility_groups do
      resources :facilities
    end

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

  authenticate :admin, lambda(&:owner?) do
    require 'sidekiq/web'
    mount Sidekiq::Web => '/sidekiq'
  end
end
