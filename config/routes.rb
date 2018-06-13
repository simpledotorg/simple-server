Rails.application.routes.draw do
  devise_scope :admin do
    authenticated :admin do
      root to: redirect("admin/facilities"), as: :admin_root
    end

    unauthenticated :admin do
      root to: "devise/sessions#new"
    end
  end

  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'

  namespace :api do
    namespace :v1 do
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
    end
  end

  devise_for :admins

  namespace :admin do
    resources :facilities
    resources :protocol_drugs
    resources :protocols
  end
end
