require "rails_helper"

RSpec.describe Api::V4::DrugStocksController, type: :controller do
  let(:user) { create(:user) }
  let(:facility_group) { user.facility.facility_group }
  let(:facility) { create(:facility, facility_group: facility_group) }

  describe "#index" do
    render_views

    it "returns the latest drug stocks for the user's facility" do
      month = Date.parse("2021-10-29")
      end_of_month = month.end_of_month
      drug_stocks = create_list(:drug_stock, 3, facility: facility, for_end_of_month: end_of_month)
      expected_drug_stock_form_url = "http://test.host/webview/drug_stocks/new?access_token=#{user.access_token}&facility_id=#{facility.id}&user_id=#{user.id}"
      expected_response = {
        "month" => "2021-10",
        "facility_id" => facility.id,
        "drug_stock_form_url" => expected_drug_stock_form_url,
        "drugs" => array_including(
          drug_stocks.map do |stock|
            {
              "protocol_drug_id" => stock.protocol_drug_id,
              "in_stock" => stock.in_stock,
              "received" => stock.received
            }
          end
        )
      }

      request.headers["X-User-Id"] = user.id
      request.headers["X-Facility-Id"] = facility.id
      request.headers["Authorization"] = "Bearer #{user.access_token}"
      request.headers["Accept"] = "application/json"

      get :index, params: {date: month}

      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)).to include(expected_response)
    end

    describe "user api authentication" do
      it "does not allow sync_from_user requests to the controller with invalid user_id and access_token" do
        request.headers["X-User-Id"] = "invalid user id"
        request.headers["X-Facility-Id"] = facility.id
        request.headers["Authorization"] = "invalid access token"

        get :index, params: {date: "2020-10-30"}

        expect(response.status).to eq(401)
      end
    end

    describe "validations" do
      it "returns a bad request if date is missing" do
        request.headers["X-User-Id"] = user.id
        request.headers["X-Facility-Id"] = facility.id
        request.headers["Authorization"] = "Bearer #{user.access_token}"

        get :index

        expect(response.status).to eq(400)
        expect(response.body).to include("date")
      end

      it "returns a bad request if date is invalid" do
        request.headers["X-User-Id"] = user.id
        request.headers["X-Facility-Id"] = facility.id
        request.headers["Authorization"] = "Bearer #{user.access_token}"

        get :index, params: {date: "invalid date"}

        expect(response.status).to eq(400)
        expect(response.body).to include("date")
      end
    end
  end
end
