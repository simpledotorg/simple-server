Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  namespace :api do
    namespace :v1 do
      scope '/patients' do
        post 'sync', to: 'patients#sync_from_user'
      end
    end
  end
end
