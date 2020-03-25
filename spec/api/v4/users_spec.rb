require 'swagger_helper'

describe 'Users v4 API', swagger_doc: 'v4/swagger.json' do
  let(:facility) { FactoryBot.create(:facility) }
  let!(:supervisor) { FactoryBot.create(:admin, :supervisor, facility_group: facility.facility_group) }
  let!(:organization_owner) { FactoryBot.create(:admin, :organization_owner, organization: facility.organization) }

  path '/users/find' do
    post 'Find a existing user' do
      tags 'User'
      parameter name: :phone_number, in: :query, type: :string, description: 'User phone number'

      let(:known_phone_number) { Faker::PhoneNumber.phone_number }
      let!(:user) { FactoryBot.create(:user, phone_number: known_phone_number, registration_facility: facility) }
      let(:id) { user.id }

      response '200', 'user is found' do
        schema Api::V4::Schema.find_user_response
        let(:phone_number) { known_phone_number }
        let(:id) { user.id }
        run_test!
      end

      response '404', 'user is not found' do
        let(:id) { SecureRandom.uuid }
        let(:phone_number) { Faker::PhoneNumber.phone_number }
        run_test!
      end
    end
  end
end
