require 'swagger_helper'

describe 'Users API' do
  path '/users/find' do
    get 'Find a existing user' do
      tags 'User'
      parameter name: :phone_number, in: :query, type: :string
      parameter name: :id, in: :query, type: :string, description: 'User UUID'

      let(:known_phone_number) { Faker::PhoneNumber.phone_number }
      let(:facility) { FactoryBot.create(:facility) }
      let!(:user) { FactoryBot.create(:user, phone_number: known_phone_number, facility_ids: [facility.id]) }
      let(:id) { user.id }

      response '200', 'user is found' do
        schema '$ref' => '#/definitions/user'
        let(:phone_number) { known_phone_number }
        let(:id) { user.id }
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
      tags 'User'
      parameter name: :user, in: :body, schema: { '$ref' => '#/definitions/user' }

      let!(:facility) { FactoryBot.create(:facility) }
      let(:phone_number) { Faker::PhoneNumber.phone_number }

      response '201', 'user is registered' do
        let(:user) do
          { user: FactoryBot.attributes_for(:user_created_on_device, facility_ids: [facility.id])
                    .merge(created_at: Time.now, updated_at: Time.now) }
        end

        schema Api::V1::Schema.user_registration_response
        before do |example|
          submit_request(example.metadata)
        end

        it 'returns a valid 201 response' do |example|
          assert_response_matches_metadata(example.metadata)
        end
      end

      response '400', 'returns bad request for invalid params' do
        let(:user) do
          { user: FactoryBot.attributes_for(:user, :created_on_device)
                    .merge(created_at: Time.now, updated_at: Time.now, facility_ids: [facility.id], full_name: nil) }
        end
        run_test!
      end

      response '400', 'returns bad request if phone number already exists' do
        let(:used_phone_number) { Faker::PhoneNumber.phone_number }
        let!(:existing_user) { FactoryBot.create(:user, phone_number: used_phone_number) }
        let(:user) do
          { user: FactoryBot.attributes_for(:user, :created_on_device, phone_number: used_phone_number)
                    .merge(created_at: Time.now, updated_at: Time.now, facility_ids: [facility.id]) }
        end
        run_test!
      end

      response '404', 'returns not found if any of the facility ids are not known' do
        let(:user) do
          { user: FactoryBot.attributes_for(:user, :created_on_device, phone_number: phone_number)
                    .merge(created_at: Time.now, updated_at: Time.now, facility_ids: [SecureRandom.uuid, facility.id]) }
        end
        run_test!
      end
    end
  end
end