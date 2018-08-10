require 'rails_helper'

def login_user
  @request.env["devise.mapping"] = Devise.mappings[:admin]
  admin = FactoryBot.create(:admin)
  sign_in admin
end

RSpec.describe Admin::UsersController, type: :controller do

  # This should return the minimal set of attributes required to create a valid
  # User. As you add validations to User, be sure to
  # adjust the attributes here as well.

  let(:facility) { FactoryBot.create(:facility) }
  let(:valid_attributes) {
    FactoryBot.attributes_for(:user, facility_id: facility.id)
  }

  let(:invalid_attributes) {
    FactoryBot.attributes_for(:user, facility_id: facility.id).merge(full_name: nil)
  }
  before(:each) do
    login_user
  end

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # UsersController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  describe 'GET #index' do
    it 'returns a success response' do
      user = User.create! valid_attributes
      get :index, params: { facility_id: facility.id }
      expect(response).to be_success
    end
  end

  describe 'GET #show' do
    it 'returns a success response' do
      user = User.create! valid_attributes
      get :show, params: { id: user.to_param, facility_id: facility.id }
      expect(response).to be_success
    end
  end

  describe 'GET #new' do
    it 'returns a success response' do
      get :new, params: { facility_id: facility.id }
      expect(response).to be_success
    end
  end

  describe 'GET #edit' do
    it 'returns a success response' do
      user = User.create! valid_attributes
      get :edit, params: { id: user.to_param, facility_id: facility.id }
      expect(response).to be_success
    end
  end

  describe 'POST #create' do
    before :each do
      sms_nofication_service = double(SmsNotificationService.new(nil))
      allow(SmsNotificationService).to receive(:new).and_return(sms_nofication_service)
      allow(sms_nofication_service).to receive(:notify).and_return(true)
    end
    context 'with valid params' do
      it 'creates a new User' do
        expect {
          post :create, params: { user: valid_attributes, facility_id: facility.id }
        }.to change(User, :count).by(1)
      end

      it 'redirects to the created user' do
        post :create, params: { user: valid_attributes, facility_id: facility.id }
        expect(response).to redirect_to([:admin, User.order(:created_at).last.facility])
      end

      it 'adds otp and otp_valid_until to the user' do
        Timecop.freeze do
          timedelta = ENV['USER_OTP_VALID_UNTIL_DELTA_IN_MINUTES'].to_i.minutes
          post :create, params: { user: valid_attributes, facility_id: facility.id }

          user = User.find_by(phone_number: valid_attributes[:phone_number])
          expect(user.otp).to be_present
          expect(user.otp_valid_until.to_i).to eq((Time.now + timedelta).to_i)
        end
      end

      it 'adds access_token to the user' do
        post :create, params: { user: valid_attributes, facility_id: facility.id }

        user = User.find_by(phone_number: valid_attributes[:phone_number])
        expect(user.access_token).to be_present
      end
    end

    context 'with invalid params' do
      it "returns a success response (i.e. to display the 'new' template)" do
        post :create, params: { user: invalid_attributes, facility_id: facility.id }
        expect(response).to be_success
      end
    end
  end

  describe 'PUT #update' do
    context 'with valid params' do
      let(:new_attributes) {
        FactoryBot.attributes_for(:user, facility_id: facility.id)
          .except(:device_created_at, :device_updated_at, :otp, :otp_valid_until)
      }

      it 'updates the requested user' do
        user = User.create! valid_attributes
        put :update, params: { id: user.to_param, user: new_attributes, facility_id: facility.id }
        user.reload
        expect(user.attributes.except(
          'id', 'created_at', 'updated_at', 'device_created_at', 'device_updated_at',
          'password_digest', 'otp', 'otp_valid_until', 'access_token', 'logged_in_at'))
          .to eq new_attributes.with_indifferent_access.except('password', 'password_confirmation')
      end

      it 'redirects to the user' do
        user = User.create! valid_attributes
        put :update, params: { id: user.to_param, user: valid_attributes, facility_id: facility.id }
        expect(response).to redirect_to([:admin, facility])
      end
    end

    context 'with invalid params' do
      it "returns a success response (i.e. to display the 'edit' template)" do
        user = User.create! valid_attributes
        put :update, params: { id: user.to_param, user: invalid_attributes, facility_id: facility.id }
        expect(response).to be_success
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the requested user' do
      user = User.create! valid_attributes
      expect {
        delete :destroy, params: { id: user.to_param, facility_id: facility.id }
      }.to change(User, :count).by(-1)
    end

    it 'redirects to the users list' do
      user = User.create! valid_attributes
      delete :destroy, params: { id: user.to_param, facility_id: facility.id }
      expect(response).to redirect_to([:admin, facility])
    end
  end

  describe 'PUT #disable_access' do
    it 'disables the access token for the user' do
      user = User.create! valid_attributes
      put :disable_access, params: { user_id: user.id, facility_id: user.facility.id }
      user.reload
      expect(user.access_token_valid?).to be false
    end
  end

  describe 'PUT #enable_access' do
    let(:user) { FactoryBot.create(:user, facility: facility) }

    before :each do
      sms_notification_service = double(SmsNotificationService.new(user))
      allow(SmsNotificationService).to receive(:new).with(user).and_return(sms_notification_service)
      expect(sms_notification_service).to receive(:notify)
    end

    it 'resets access token' do
      old_access_token = user.access_token
      put :enable_access, params: { user_id: user.id, facility_id: facility.id }
      user.reload
      expect(user.access_token_valid?).to be true
      expect(user.access_token).not_to eq(old_access_token)
    end

    it 'resets OTP' do
      old_otp = user.otp
      put :enable_access, params: { user_id: user.id, facility_id: facility.id }
      user.reload
      expect(user.otp_valid?).to be true
      expect(user.otp).not_to eq(old_otp)
    end

    it 'resets logged_in_at' do
      put :enable_access, params: { user_id: user.id, facility_id: facility.id }
      user.reload
      expect(user.logged_in_at).to be nil
      end

    it 'sets sync_approval_status to allowed' do
      put :enable_access, params: { user_id: user.id, facility_id: facility.id }
      user.reload
      expect(user.sync_approval_status_allowed?).to be true
    end
  end
end
