require 'swagger_helper'

describe 'Users API' do
  path '/users/find' do
    get 'Find a existing user' do
      tags 'user'
      parameter name: :phone_number, in: :query, type: :string

      let(:known_phone_number) { Faker::PhoneNumber.phone_number }
      let(:facility) { FactoryBot.create(:facility) }
      let!(:user) { FactoryBot.create(:user, phone_number: known_phone_number, facility_id: facility.id) }

      response '200', 'user is found' do
        schema Api::V1::Schema::Models.user
        let(:phone_number) { known_phone_number }
        run_test!
      end

      response '404', 'user is found' do
        let(:phone_number) { Faker::PhoneNumber.phone_number }
        run_test!
      end
    end
  end

  path '/users/register' do
    post 'Register a new user' do
      tags 'user'
      parameter name: :user, in: :body, type: Api::V1::Schema::Models.user

      let!(:facility) { FactoryBot.create(:facility) }
      let(:phone_number) { Faker::PhoneNumber.phone_number }

      response '201', 'user is registered' do
        schema Api::V1::Schema.user_registration_response
        let(:user) do
          FactoryBot.attributes_for(:user, :created_on_device, facility_id: facility.id)
            .merge(created_at: Time.now, updated_at: Time.now)
        end

        run_test!
      end

      response '400', 'returns bad request for invalid params' do
        let(:user) do
          FactoryBot.attributes_for(:user, :created_on_device, facility_id: facility.id)
            .merge(created_at: Time.now, updated_at: Time.now, full_name: nil)
        end
        run_test!
      end

      response '400', 'returns bad request if phone number already exists' do
        let(:user) do
          FactoryBot.create(:user, phone_number: phone_number)
          FactoryBot.attributes_for(:user, :created_on_device, phone_number: phone_number, facility_id: facility.id)
            .merge(created_at: Time.now, updated_at: Time.now, full_name: nil)
        end
        run_test!
      end
    end
  end
end