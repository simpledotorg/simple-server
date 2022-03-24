require "rails_helper"

RSpec.describe Api::V4::DrugStocksController, type: :controller do
  let(:request_user) { create(:user) }
  let(:request_facility_group) { request_user.facility.facility_group }
  let(:request_facility) { create(:facility, facility_group: request_facility_group) }

  describe "user api authentication" do
    it "does not allow sync_from_user requests to the controller with invalid user_id and access_token" do
      request.headers["X-User-Id"] = "invalid user id"
      request.headers["X-Facility-Id"] = request_facility.id
      request.headers["Authorization"] = "invalid access token"

      get :index, params: {date: "2020-10-30"}

      expect(response.status).to eq(401)
    end
  end

  describe "validations" do
    it "returns a bad request if date is missing" do
      request.headers["X-User-Id"] = request_user.id
      request.headers["X-Facility-Id"] = request_facility.id
      request.headers["Authorization"] = "Bearer #{request_user.access_token}"

      get :index

      expect(response.status).to eq(400)
      expect(response.body).to include("date")
    end

    it "returns a bad request if date is invalid" do
      request.headers["X-User-Id"] = request_user.id
      request.headers["X-Facility-Id"] = request_facility.id
      request.headers["Authorization"] = "Bearer #{request_user.access_token}"

      get :index, params: {date: "invalid date"}

      expect(response.status).to eq(400)
      expect(response.body).to include("date")
    end
  end
end
