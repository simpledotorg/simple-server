# frozen_string_literal: true

require "rails_helper"

def login_user
  @request.env["devise.mapping"] = Devise.mappings[:admin]
  admin = FactoryBot.create(:admin, :power_user)
  sign_in admin.email_authentication
end

RSpec.describe Admin::UsersController, type: :controller do
  # This should return the minimal set of attributes required to create a valid
  # User. As you add validations to User, be sure to
  # adjust the attributes here as well.

  let(:facility) { FactoryBot.create(:facility) }
  let(:valid_attributes) do
    FactoryBot.attributes_for(:user).merge(registration_facility_id: facility.id)
  end

  let(:invalid_attributes) do
    FactoryBot.attributes_for(:user, facility_id: facility.id).merge(full_name: nil)
  end
  before(:each) do
    login_user
  end

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # UsersController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  describe "GET #index" do
    it "returns a success response" do
      create(:user)
      get :index, params: {facility_id: facility.id}
      expect(response).to be_successful
    end

    it "returns a subset of filtered users by search term" do
      user1 = create(:user, full_name: "Doctor Jack")
      _user = create(:user, full_name: "Jack")

      get :index, params: {facility_id: facility.id, search_query: "Doctor"}
      expect(assigns(:users)).to match_array(user1)
      expect(response).to be_successful
    end

    it "fetches no users for search term with no matches" do
      create(:user, full_name: "Doctor Jack")
      create(:user, full_name: "Jack")

      get :index, params: {facility_id: facility.id, search_query: "Shephard"}
      expect(assigns(:users)).to match_array([])
      expect(response).to be_successful
    end
  end

  describe "GET #teleconsult_search" do
    context ".json" do
      render_views

      it "fetches users in the facility group for search term" do
        facility = create(:facility)
        create(:user, full_name: "Doctor Jack", registration_facility: facility)
        create(:user, full_name: "Jack", registration_facility: facility)

        params = {search_query: "Doctor", facility_group_id: facility.facility_group_id}

        get :teleconsult_search, format: :json, params: params

        expect(response).to be_successful
        expect(JSON(response.body).first["full_name"]).to eq "Doctor Jack"
      end

      it "should call teleconsult_search and return the results" do
        search_query = "Search query"
        facility = create(:facility)
        user = create(:user)
        params = {search_query: search_query, facility_group_id: facility.facility_group_id}

        allow(User).to receive(:teleconsult_search).with(search_query).and_return([user])

        get :teleconsult_search, format: :json, params: params

        expect(JSON(response.body).first["full_name"]).to eq user.full_name
      end
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      user = create(:user)
      get :show, params: {id: user.to_param, facility_id: facility.id}
      expect(response).to be_successful
    end
  end

  describe "GET #edit" do
    it "returns a success response" do
      user = create(:user)
      get :edit, params: {id: user.to_param, facility_id: facility.id}
      expect(response).to be_successful
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) do
        register_user_request_params(registration_facility_id: facility.id)
          .except(:id, :password_digest)
      end

      it "updates the requested user" do
        user = create(:user)
        put :update, params: {id: user.to_param, user: new_attributes, facility_id: facility.id}
        user.reload
        expect(user.full_name).to eq(new_attributes[:full_name])
        expect(user.phone_number).to eq(new_attributes[:phone_number])
      end

      it "redirects to the user" do
        user = create(:user)
        put :update, params: {id: user.to_param, user: valid_attributes}
        expect(response).to redirect_to(admin_user_url(user))
      end
    end

    context "with invalid params" do
      it "returns a success response (i.e. to display the 'edit' template)" do
        user = create(:user)
        put :update, params: {id: user.to_param, user: invalid_attributes, facility_id: facility.id}
        expect(response.status).to eq(200)
      end
    end
  end

  describe "PUT #disable_access" do
    it "disables the access token for the user" do
      user = create(:user)
      put :disable_access, params: {user_id: user.id, facility_id: user.facility.id}
      user.reload
      expect(user.access_token_valid?).to be false
    end
  end

  describe "PUT #enable_access" do
    let(:user) { FactoryBot.create(:user, registration_facility: facility) }

    it "sets sync_approval_status to allowed" do
      put :enable_access, params: {user_id: user.id, facility_id: facility.id}
      user.reload
      expect(user.sync_approval_status_allowed?).to be true
    end
  end

  describe "PUT #reset_otp" do
    let(:user) { FactoryBot.create(:user, registration_facility: facility) }

    before :each do
      allow(RequestOtpSmsJob).to receive(:perform_later).with(instance_of(User))
    end

    it "resets OTP" do
      expect(RequestOtpSmsJob).to receive(:perform_later).with(user)

      old_otp = user.otp
      put :reset_otp, params: {user_id: user.id, facility_id: facility.id}
      user.reload
      expect(user.otp_valid?).to be true
      expect(user.otp).not_to eq(old_otp)
    end
  end
end
