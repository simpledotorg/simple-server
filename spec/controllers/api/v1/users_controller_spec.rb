require 'rails_helper'

RSpec.describe Api::V1::UsersController, type: :controller do
  describe '#register_user' do
    describe 'registration payload is invalid' do
      let(:request_params) { { user: FactoryBot.attributes_for(:user).slice(:full_name, :phone_number) } }
      it 'responds with 400' do
        post :create, params: request_params

        expect(response.status).to eq(400)
      end
    end

    describe 'registration payload is valid' do
      let(:facility) { FactoryBot.create(:facility) }
      let(:user) do
        FactoryBot.attributes_for(:user)
          .slice(:full_name, :phone_number)
          .merge(password: 1234,
                 password_confirmation: 1234,
                 facility_id: facility.id)
      end

      it 'creates a user, and responds with the created user object' do
        post :create, params: { user: user }

        created_user = User.find_by(full_name: user[:full_name], phone_number: user[:phone_number])
        expect(response.status).to eq(201)
        expect(created_user).to be_present
        expect(JSON(response.body)['user'].with_int_timestamps.except('device_updated_at', 'device_created_at'))
          .to eq(created_user.as_json.with_int_timestamps.except('device_updated_at', 'device_created_at'))
      end
    end
  end
end
