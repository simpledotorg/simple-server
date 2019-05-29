require 'rails_helper'

RSpec.describe Api::Current::UsersController, type: :controller do
  let(:supervisor) { create(:admin, :supervisor) }
  let(:organization_owner) { create(:admin, :organization_owner) }
  let(:facility) { create(:facility) }
  let!(:owner) { create(:admin, :owner) }

  before :each do
    create(:admin_access_control, admin: supervisor, access_controllable: facility.facility_group)
    create(:admin_access_control, admin: organization_owner, access_controllable: facility.organization)
  end

  describe '#register' do
    describe 'registration payload is invalid' do
      let(:request_params) { { user: attributes_for(:user).slice(:full_name, :phone_number) } }
      it 'responds with 400' do
        post :register, params: request_params

        expect(response.status).to eq(400)
      end
    end

    describe 'registration payload is valid' do
      let(:user_params) do
        attributes_for(:user)
          .slice(:full_name, :phone_number)
          .merge(id: SecureRandom.uuid,
                 password_digest: BCrypt::Password.create("1234"),
                 registration_facility_id: facility.id,
                 created_at: Time.now.iso8601,
                 updated_at: Time.now.iso8601)
      end
      let(:phone_number) { user_params[:phone_number] }
      let(:password_digest) { user_params[:password_digest] }

      it 'creates a user, and responds with the created user object and their access token' do
        post :register, params: { user: user_params }
        parsed_response = JSON(response.body)

        created_user = MasterUser.find_by(full_name: user_params[:full_name])
        expect(response.status).to eq(200)
        expect(created_user).to be_present
        expect(created_user.phone_number_authentication).to be_present
        expect(created_user.phone_number_authentication.phone_number).to eq(user_params[:phone_number])

        expect(parsed_response['user'].except('created_at',
                                              'updated_at',
                                              'facility_ids').with_int_timestamps)
          .to eq(created_user.attributes
                   .except(
                     'device_updated_at',
                     'device_created_at',
                     'created_at',
                     'updated_at',
                     'sync_approval_status',
                     'sync_approval_status_reason')
                   .merge('registration_facility_id' => facility.id, 'phone_number' => phone_number, 'password_digest' => password_digest)
                   .as_json
                   .with_int_timestamps)

        expect(parsed_response['user']['registration_facility_id']).to eq(facility.id)
        expect(parsed_response['access_token']).to eq(created_user.access_token)
      end

      it 'sets the user status to requested' do
        post :register, params: { user: user_params }
        created_user = MasterUser.find_by(full_name: user_params[:full_name])
        expect(created_user.sync_approval_status).to eq(User.sync_approval_statuses[:requested])
        expect(created_user.sync_approval_status_reason).to eq(I18n.t('registration'))
      end

      it 'sets the user status to approved if AUTO_APPROVE_USER_FOR_QA feature is enabled' do
        allow(FeatureToggle).to receive(:enabled?).with('MASTER_USER_AUTHENTICATION').and_return(true)
        allow(FeatureToggle).to receive(:enabled?).with('FIXED_OTP_ON_REQUEST_FOR_QA').and_return(false)
        allow(FeatureToggle).to receive(:enabled?).with('AUTO_APPROVE_USER_FOR_QA').and_return(true)

        post :register, params: { user: user_params }
        created_user = MasterUser.find_by(full_name: user_params[:full_name])
        expect(created_user.sync_approval_status).to eq(User.sync_approval_statuses[:allowed])
      end

      it 'sends an email to a list of owners and supervisors' do
        post :register, params: { user: user_params }
        approval_email = ActionMailer::Base.deliveries.last
        expect(approval_email.to).to include(supervisor.email)
        expect(approval_email.cc).to include(organization_owner.email)
        expect(approval_email.body.to_s).to match(Regexp.quote(user_params[:phone_number]))
      end

      it 'sends an email with owners in the bcc list' do
        post :register, params: { user: user_params }
        approval_email = ActionMailer::Base.deliveries.last
        expect(approval_email.bcc).to include(owner.email)
      end

      it 'sends an approval email with list of accessible facilities' do
        post :register, params: { user: user_params }
        approval_email = ActionMailer::Base.deliveries.last
        facility.facility_group.facilities.each do |facility|
          expect(approval_email.body.to_s).to match(Regexp.quote(facility.name))
        end
      end
    end
  end

  describe '#find' do
    let(:phone_number) { Faker::PhoneNumber.phone_number }
    let(:facility) { create(:facility) }
    let!(:db_users) do
      create_list(:master_user, 10,
                  :with_phone_number_authentication,
                  registration_facility: facility)
    end
    let!(:user) { create(:master_user,
                         :with_phone_number_authentication,
                         phone_number: phone_number,
                         registration_facility: facility) }

    it 'lists the users with the given phone number' do
      get :find, params: { phone_number: phone_number }
      expect(response.status).to eq(200)
      expect(JSON(response.body).with_int_timestamps)
        .to eq(Api::Current::UserTransformer.to_response(user).with_int_timestamps)
    end

    it 'lists the users with the given id' do
      get :find, params: { id: user.id }
      expect(response.status).to eq(200)
      expect(JSON(response.body).with_int_timestamps)
        .to eq(Api::Current::UserTransformer.to_response(user).with_int_timestamps)
    end

    it 'returns 404 when user is not found' do
      get :find, params: { phone_number: Faker::PhoneNumber.phone_number }
      expect(response.status).to eq(404)
    end
  end

  describe '#request_otp' do
    let(:user) { FactoryBot.create(:master_user, :with_phone_number_authentication) }

    it "returns 404 if the user with id doesn't exist" do
      post :request_otp, params: { id: SecureRandom.uuid }

      expect(response.status).to eq(404)
    end

    it "updates the user otp and sends an sms to the user's phone number with the new otp" do
      existing_otp = user.otp
      sms_notification_service = double(SmsNotificationService.new(nil))
      expect(SmsNotificationService).to receive(:new).and_return(sms_notification_service)
      expect(sms_notification_service).to receive(:send_request_otp_sms).and_return(true)

      post :request_otp, params: { id: user.id }
      user.reload
      expect(user.otp).not_to eq(existing_otp)
    end
  end

  describe '#reset_password' do
    let(:user) { FactoryBot.create(:master_user, :with_phone_number_authentication) }
    let(:facility) { FactoryBot.create(:facility, facility_group: user.facility_group) }

    before(:each) do
      request.env['HTTP_X_USER_ID'] = user.id
      request.env['HTTP_X_FACILITY_ID'] = facility.id
      request.env['HTTP_AUTHORIZATION'] = "Bearer #{user.access_token}"
    end

    it 'Resets the password for the given user with the given digest' do
      new_password_digest = BCrypt::Password.create('1234').to_s
      post :reset_password, params: { id: user.id, password_digest: new_password_digest }
      user.reload
      expect(response.status).to eq(200)
      expect(user.phone_number_authentication.password_digest).to eq(new_password_digest)
      expect(user.sync_approval_status).to eq('requested')
      expect(user.sync_approval_status_reason).to eq(I18n.t('reset_password'))
    end

    it 'Returns 401 if the user is not authorized' do
      request.env['HTTP_AUTHORIZATION'] = 'an invalid access token'
      post :reset_password, params: { id: user.id }
      expect(response.status).to eq(401)
    end

    it 'Returns 401 if the user is not present' do
      request.env['HTTP_X_USER_ID'] = SecureRandom.uuid
      post :reset_password, params: { id: SecureRandom.uuid }
      expect(response.status).to eq(401)
    end

    it 'Sends an email to a list of owners and supervisors' do
      post :reset_password, params: { id: user.id, password_digest: BCrypt::Password.create('1234').to_s }
      approval_email = ActionMailer::Base.deliveries.last
      expect(approval_email).to be_present
      expect(approval_email.to).to include(supervisor.email)
      expect(approval_email.cc).to include(organization_owner.email)
      expect(approval_email.body.to_s).to match(Regexp.quote(user.phone_number))
      expect(approval_email.body.to_s).to match("reset")
    end
  end
end
