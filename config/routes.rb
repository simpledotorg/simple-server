Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

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

  namespace :admin do
    resources :facilities
    resources :protocol_drugs
    resources :protocols
  end
end
