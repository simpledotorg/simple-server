require "rails_helper"

RSpec.describe Api::V4::DrugStocksController, type: :controller do
  let(:request_user) { create(:user) }
  let(:request_facility_group) { request_user.facility.facility_group }
  let(:request_facility) { create(:facility, facility_group: request_facility_group) }

  before :each do
    request.env["X_USER_ID"] = request_user.id
    request.env["X_FACILITY_ID"] = request_facility.id
    request.env["HTTP_AUTHORIZATION"] = "Bearer #{request_user.access_token}"
  end

  describe "user api authentication" do
    it "does not allow sync_from_user requests to the controller with invalid user_id and access_token" do
      request.env["X_USER_ID"] = "invalid user id"
      request.env["HTTP_AUTHORIZATION"] = "invalid access token"

      get :index, params: {date: "2020-10-30"}

      expect(response.status).to eq(401)
    end
  end

  describe "validations" do
    it "returns"
  end
end
