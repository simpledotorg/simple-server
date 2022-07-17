Rails.application.routes.draw do
  resources :home

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

  namespace :webview do
    resources :drug_stocks, only: [:new, :create, :index]
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

        get "generate_id", to: "encounters#generate_id"
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

      scope :facility_medical_officers do
        get "sync", to: "facility_medical_officers#sync_to_user"
      end

      scope :teleconsultations do
        post "sync", to: "teleconsultations#sync_from_user"
      end

      scope :medications do
        get "sync", to: "medications#sync_to_user"
      end

      scope :patients do
        post "/lookup", to: "patients#lookup"
      end

      scope :call_results do
        post "/sync", to: "call_results#sync_from_user"
      end

      namespace :analytics do
        resource :overdue_list, only: [:show]
      end

      resources :drug_stocks, only: [:index]

      get "states", to: "states#index"
    end
  end

  devise_for :email_authentications,
    path: "email_authentications",
    controllers: {
      invitations: "email_authentications/invitations",
      passwords: "email_authentications/passwords",
      sessions: "email_authentications/sessions"
    }

  post "email_authentications/validate", to: "email_authentications/password_validations#create"

  resources :admins do
    member do
      get "access_tree/:page", to: "admins#access_tree", as: :access_tree
      post "resend_invitation", to: "admins#resend_invitation", as: :resend_invitation
    end
  end

  resources :appointments, only: [:index, :update]

  get "/dashboard", to: redirect("/reports/regions/")
  get "/dashboard/districts/", to: redirect("/reports/districts/")
  get "/dashboard/districts/:slug", to: redirect("/reports/districts/%{slug}")
  get "/reports/districts/", to: redirect("/reports/regions/")

  namespace :reports do
    resources :patient_lists, only: [:show]
    resources :progress, only: [:show]
    resources :regions, only: [:index]
    get "regions/fastindex", to: "regions#fastindex"
    get "regions/:report_scope/:id", to: "regions#show", as: :region
    get "regions/:report_scope/:id/details", to: "regions#details", as: :region_details
    get "regions/:report_scope/:id/cohort", to: "regions#cohort", as: :region_cohort
    get "regions/:report_scope/:id/download", to: "regions#download", as: :region_download
    get "regions/:report_scope/:id/monthly_state_data_report",
      to: "regions#hypertension_monthly_state_data", as: :region_hypertension_monthly_state_data
    get "regions/:report_scope/:id/monthly_district_report",
      to: "regions#hypertension_monthly_district_report", as: :region_hypertension_monthly_district_report
    get "regions/:report_scope/:id/monthly_district_data_report",
      to: "regions#hypertension_monthly_district_data", as: :region_hypertension_monthly_district_data
    get "regions/:report_scope/:id/graphics", to: "regions#whatsapp_graphics", as: :graphics

    get "regions/:report_scope/:id/diabetes", to: "regions#diabetes", as: :region_diabetes
    get "regions/:report_scope/:id/diabetes/monthly_state_data_report",
      to: "regions#diabetes_monthly_state_data", as: :region_diabetes_monthly_state_data
    get "regions/:report_scope/:id/diabetes/monthly_district_report",
      to: "regions#diabetes_monthly_district_report", as: :region_diabetes_monthly_district_report
    get "regions/:report_scope/:id/diabetes/monthly_district_data_report",
      to: "regions#diabetes_monthly_district_data", as: :region_diabetes_monthly_district_data
  end

  resource :regions_search, controller: "regions_search"

  namespace :my_facilities do
    root to: "/my_facilities#index", as: "overview"
    get "blood_pressure_control", to: redirect("/my_facilities/bp_controlled")
    get "csv_maker", to: "csv_maker" ##################### DO I KEEP THIS ROUTE I MADE
    get "bp_controlled", to: "bp_controlled"
    get "bp_not_controlled", to: "bp_not_controlled"
    get "registrations", to: redirect("/my_facilities/")
    get "missed_visits", to: "missed_visits"
    get "facility_performance", to: "facility_performance#show"
    get "drug_stocks", to: "drug_stocks#drug_stocks"
    get "drug_consumption", to: "drug_stocks#drug_consumption"
    post "drug_stocks", to: "drug_stocks#create"
    get "drug_stocks/:region_id/new", to: "drug_stocks#new", as: :drug_stock_form
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

    resources :facility_groups, except: [:index] do
      resources :facilities
    end

    resources :patient_imports, only: [:new, :create]

    resources :protocols do
      resources :protocol_drugs
    end

    resources :users do
      get "teleconsult_search", on: :collection, to: "users#teleconsult_search"
      put "reset_otp", to: "users#reset_otp"
      put "disable_access", to: "users#disable_access"
      put "enable_access", to: "users#enable_access"
    end

    # This is a temporary page to assist in clean up
    get "fix_zone_data", to: "fix_zone_data#show"
    post "update_zone", to: "fix_zone_data#update"

    get "deduplication", to: "deduplicate_patients#show"
    post "deduplication", to: "deduplicate_patients#merge"

    resources :error_traces, only: [:index, :create]
  end

  authenticate :email_authentication, ->(a) { a.user.power_user? } do
    require "sidekiq/web"
    mount Sidekiq::Web => "/sidekiq"
  end

  authenticate :email_authentication, ->(a) { a.user.power_user? } do
    mount Flipper::UI.app(Flipper) => "/flipper"
  end
end
