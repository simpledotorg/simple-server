Rails.application.routes.draw do
  devise_scope :email_authentication do
    authenticated :email_authentication do
      root to: "admin#root"
    end

    unauthenticated :email_authentication do
      root to: "devise/sessions#new"
    end
  end

  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"

  concern :sync_routes do
    scope "/patients" do
      get "sync", to: "patients#sync_to_user"
      post "sync", to: "patients#sync_from_user"
    end

    scope "/blood_pressures" do
      get "sync", to: "blood_pressures#sync_to_user"
      post "sync", to: "blood_pressures#sync_from_user"
    end

    scope "/blood_sugars" do
      get "sync", to: "blood_sugars#sync_to_user"
      post "sync", to: "blood_sugars#sync_from_user"
    end

    scope "/prescription_drugs" do
      get "sync", to: "prescription_drugs#sync_to_user"
      post "sync", to: "prescription_drugs#sync_from_user"
    end

    scope "/facilities" do
      get "sync", to: "facilities#sync_to_user"
    end

    scope "/protocols" do
      get "sync", to: "protocols#sync_to_user"
    end

    scope "/appointments" do
      get "sync", to: "appointments#sync_to_user"
      post "sync", to: "appointments#sync_from_user"
    end

    scope "/medical_histories" do
      get "sync", to: "medical_histories#sync_to_user"
      post "sync", to: "medical_histories#sync_from_user"
    end
  end

  namespace :api, defaults: {format: "json"} do
    get "manifest.json", to: "manifests#show"

    # Returning HTTP Status `410` for deprecated API version `v1`
    namespace :v1 do
      match "*all", via: [:get, :post, :put, :delete, :patch], to: proc { [410, {}, [""]] }
    end

    namespace :v2 do
      match "*all", via: [:get, :post, :put, :delete, :patch], to: proc { [410, {}, [""]] }
    end

    namespace :v3, path: "v3" do
      get "ping", to: "pings#show"
      post "login", to: "logins#login_user"

      # Exotel requires all endpoints to be GET
      scope :exotel_call_sessions do
        get "fetch", to: "exotel_call_sessions#fetch"
        get "create", to: "exotel_call_sessions#create"
        get "terminate", to: "exotel_call_sessions#terminate"
      end

      resource :twilio_sms_delivery, only: [:create], controller: :twilio_sms_delivery

      scope :users do
        get "find", to: "users#find"
        post "register", to: "users#register"
        post "/:id/request_otp", to: "users#request_otp"
        post "/me/reset_password", to: "users#reset_password"
      end

      concerns :sync_routes

      scope "/encounters" do
        get "sync", to: "encounters#sync_to_user"
        post "sync", to: "encounters#sync_from_user"

        if FeatureToggle.enabled?("GENERATE_ENCOUNTER_ID_ENDPOINT")
          get "generate_id", to: "encounters#generate_id"
        end
      end

      resource :help, only: [:show], controller: "help"

      namespace :analytics do
        resource :user_analytics, only: [:show]
      end
    end

    namespace :v4, path: "v4" do
      scope :blood_sugars do
        get "sync", to: "blood_sugars#sync_to_user"
        post "sync", to: "blood_sugars#sync_from_user"
      end

      resource :patient, controller: "patient", only: [:show] do
        post "activate", to: "patient#activate"
        post "login", to: "patient#login"
      end

      scope :users do
        post "find", to: "users#find"
        post "activate", to: "users#activate"
        get "me", to: "users#me"
      end

      scope :facility_teleconsultations do
        get "/:facility_id", to: "facility_teleconsultations#show"
      end
    end
  end

  devise_for :email_authentications,
    path: "email_authentications",
    controllers: {invitations: "email_authentications/invitations"}

  resources :admins

  namespace :analytics do
    resources :facilities, only: [:show] do
      get "graphics", to: "facilities#whatsapp_graphics"
      get "patient_list", to: "facilities#patient_list"
      get "patient_list_with_history", to: "facilities#patient_list"
      get "share", to: "facilities#share_anonymized_data"
    end

    resources :organizations do
      resources :districts, only: [:show] do
        get "graphics", to: "districts#whatsapp_graphics"
        get "patient_list", to: "districts#patient_list"
        get "patient_list_with_history", to: "districts#patient_list_with_history"
        get "share", to: "districts#share_anonymized_data"
      end
    end
  end

  resources :appointments, only: [:index, :update]
  resources :patients do
    collection do
      get :lookup
    end
  end
  resources :organizations, only: [:index], path: "dashboard"

  get "/dashboard/districts/preview", to: redirect("/dashboard/districts")
  namespace :dashboard do
    resources :districts do
    end
  end

  namespace :my_facilities do
    root to: "/my_facilities#index", as: "overview"
    get "ranked_facilities", to: "ranked_facilities"
    get "blood_pressure_control", to: "blood_pressure_control"
    get "registrations", to: "registrations"
    get "missed_visits", to: "missed_visits"
  end

  scope :resources do
    get "/", to: "resources#index", as: "resources"
  end

  namespace :admin do
    resources :organizations

    resources :facilities, only: [:index] do
      collection do
        get "upload"
        post "upload"
      end
    end
    resources :facility_groups do
      resources :facilities
    end

    resources :protocols do
      resources :protocol_drugs
    end

    resources :users do
      put "reset_otp", to: "users#reset_otp"
      put "disable_access", to: "users#disable_access"
      put "enable_access", to: "users#enable_access"
    end
  end

  if FeatureToggle.enabled?("PURGE_ENDPOINT_FOR_QA")
    namespace :qa do
      delete "purge", to: "purges#purge_patient_data"
    end
  end

  authenticate :email_authentication, ->(a) { a.user.has_permission?(:view_sidekiq_ui) } do
    require "sidekiq/web"
    mount Sidekiq::Web => "/sidekiq"
  end

  authenticate :email_authentication, ->(a) { a.user.has_permission?(:view_flipper_ui) } do
    mount Flipper::UI.app(Flipper) => "/flipper"
  end
end
