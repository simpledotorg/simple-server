Rails.application.routes.draw do
  resources :protocol_drugs
  resources :protocols
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
    end
  end
end
