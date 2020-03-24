require 'rails_helper'

RSpec.describe Api::V4::UsersController, type: :controller do
  describe '#find' do
    let!(:user) { create(:user, phone_number: '1234567890') }

    it 'lists the users with the given phone number' do
      post :find, params: { phone_number: '1234567890' }
      expect(response.status).to eq(200)
      expect(JSON(response.body).with_int_timestamps)
        .to eq(Api::V3::UserTransformer.to_response(user).with_int_timestamps)
    end

    it 'returns 404 when user is not found' do
      post :find, params: { phone_number: '0987654321' }
      expect(response.status).to eq(404)
    end
  end
end
