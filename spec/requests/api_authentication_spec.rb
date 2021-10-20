require "rails_helper"

RSpec.describe "Api authentication", type: :request, skip_request_store_clear: true do
  include Devise::Test::IntegrationHelpers

  before do
    Thread.current[:request_store] = {}
    # to ensure request store doesn't get cleared in the middle of request specs
    allow(RequestStore).to receive(:clear!)
  end

  after do
    Thread.current[:request_store] = {}
  end

  let(:request_user) { create(:user_created_on_device) }

  context "successful login" do
    let(:headers) do
      {"ACCEPT" => "application/json",
       "CONTENT_TYPE" => "application/json",
       "HTTP_X_USER_ID" => request_user.id,
       "HTTP_X_FACILITY_ID" => request_user.facility.id,
       "HTTP_AUTHORIZATION" => "Bearer #{request_user.access_token}"}
    end

    it "tracks current user info in request store" do
      get "/api/v3/blood_pressures/sync", params: {}, headers: headers

      expect(response.status).to eq 200

      expect(RequestStore.store[:current_user][:id]).to eq(request_user.id)
      expect(RequestStore.store[:current_user][:access_level]).to be_nil
      expect(RequestStore.store[:current_user][:sync_approval_status]).to eq("allowed")
    end
  end

  context "failed login" do
    let(:headers) do
      {"ACCEPT" => "application/json",
       "CONTENT_TYPE" => "application/json",
       "HTTP_X_USER_ID" => request_user.id,
       "HTTP_X_FACILITY_ID" => request_user.facility.id,
       "HTTP_AUTHORIZATION" => "Bearer bad token"}
    end

    it "does not track anything in request store" do
      expect(RequestStore.store[:current_user]).to be_nil
      get "/api/v3/blood_pressures/sync", params: {}, headers: headers

      expect(response.status).to eq 401

      expect(RequestStore.store[:current_user]).to be_nil
    end
  end
end
