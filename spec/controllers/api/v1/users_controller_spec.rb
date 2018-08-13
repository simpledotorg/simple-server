require 'rails_helper'

RSpec.describe Api::V1::UsersController, type: :controller do
  describe '#register' do
    describe 'registration payload is invalid' do
      let(:request_params) { { user: FactoryBot.attributes_for(:user).slice(:full_name, :phone_number) } }
      it 'responds with 400' do
        post :register, params: request_params

        expect(response.status).to eq(400)
      end
    end

    describe 'registration payload is valid' do
      let(:facility) { FactoryBot.create(:facility) }
      let(:user_params) do
        FactoryBot.attributes_for(:user)
          .slice(:full_name, :phone_number)
          .merge(id: SecureRandom.uuid,
                 password_digest: BCrypt::Password.create("1234"),
                 facility_ids: [facility.id],
                 created_at: Time.now.iso8601,
                 updated_at: Time.now.iso8601)
      end

      it 'creates a user, and responds with the created user object' do
        post :register, params: { user: user_params }

        created_user = User.find_by(full_name: user_params[:full_name], phone_number: user_params[:phone_number])
        expect(response.status).to eq(201)
        expect(created_user).to be_present
        expect(JSON(response.body)['user'].except('device_updated_at', 'device_created_at', 'facility_ids').with_int_timestamps)
          .to eq(created_user.attributes
                   .except(
                     'device_updated_at',
                     'device_created_at',
                     'access_token',
                     'logged_in_at',
                     'otp',
                     'otp_valid_until')
                   .as_json
                   .with_int_timestamps)
        expect(JSON(response.body)['user']['facility_ids']).to match_array(created_user.facilities.map(&:id))
      end

      it 'sets the user status to requested' do
        post :register, params: { user: user_params }
        created_user = User.find_by(full_name: user_params[:full_name], phone_number: user_params[:phone_number])
        expect(created_user.sync_approval_status).to eq(User.sync_approval_statuses[:requested])
      end

      it 'sends an email to a list of owners and supervisors' do
        post :register, params: { user: user_params }
        approval_email = ActionMailer::Base.deliveries.last
        expect(ENV['SUPERVISOR_EMAILS']).to match(/#{Regexp.quote(approval_email.to.first)}/)
        expect(ENV['OWNER_EMAILS']).to match(/#{Regexp.quote(approval_email.cc.first)}/)
        # expect(approval_email.body.to_s).to match(user_params[:phone_number])
      end
    end
  end

  describe '#find' do
    let(:phone_number) { Faker::PhoneNumber.phone_number }
    let(:facility) { FactoryBot.create(:facility) }
    let!(:db_users) { FactoryBot.create_list(:user, 10, facility_ids: [facility.id]) }
    let!(:user) { FactoryBot.create(:user, phone_number: phone_number, facility_ids: [facility.id]) }
    it 'lists the users with the given phone number' do
      get :find, params: { phone_number: phone_number }
      expect(response.status).to eq(200)
      expect(JSON(response.body).except('facility_ids').with_int_timestamps)
        .to eq(Api::V1::UserTransformer.to_response(user).except(:facility_ids).with_int_timestamps)
      expect(JSON(response.body)['facility_ids']).to match_array(user.facility_ids)
    end

    it 'lists the users with the given id' do
      get :find, params: { id: user.id }
      expect(response.status).to eq(200)
      expect(JSON(response.body).except('facility_ids').with_int_timestamps)
        .to eq(Api::V1::UserTransformer.to_response(user).except(:facility_ids).with_int_timestamps)
      expect(JSON(response.body)['facility_ids']).to match_array(user.facility_ids)
    end

    it 'returns 404 when user is not found' do
      get :find, params: { phone_number: Faker::PhoneNumber.phone_number }
      expect(response.status).to eq(404)
    end
  end
end
