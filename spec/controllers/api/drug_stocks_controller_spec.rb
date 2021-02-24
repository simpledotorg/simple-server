require "rails_helper"

RSpec.describe Api::DrugStocksController, type: :controller do
  before do
    Flipper.enable(:drug_stocks)
  end

  after do
    Flipper.disable(:drug_stocks)
  end

  describe "POST #create" do
    let(:power_user) { create(:user) }
    let(:facility_group) { create(:facility_group) }

    def set_headers(user, facility)
      request.env["HTTP_X_USER_ID"] = user.id
      request.env["HTTP_X_FACILITY_ID"] = facility.id
      request.env["HTTP_AUTHORIZATION"] = "Bearer #{user.access_token}"
    end

    it "creates drug stock records and sends JSON success response" do
      facility = create(:facility, facility_group: power_user.facility.facility_group)
      protocol_drug = create(:protocol_drug, stock_tracked: true, protocol: facility.facility_group.protocol)
      set_headers(power_user, facility)
      params = {
        facility_id: facility.id,
        for_end_of_month: Date.today.strftime("%b-%Y"),
        drug_stocks: [{
          protocol_drug_id: protocol_drug.id,
          received: 10,
          in_stock: 20
        }]
      }

      expect {
        post :create, params: params
        expect(response).to be_successful
      }.to change { DrugStock.count }.by(1)
      expect(JSON.parse(response.body)).to eq({"status" => "OK"})
    end

    it "sends error messages for invalid saves" do
      facility = create(:facility, facility_group: power_user.facility.facility_group)
      protocol_drug = create(:protocol_drug, stock_tracked: true, protocol: facility.facility_group.protocol)
      set_headers(power_user, facility)
      params = {
        facility_id: facility.id,
        for_end_of_month: Date.today.strftime("%b-%Y"),
        drug_stocks: [{
          protocol_drug_id: protocol_drug.id,
          received: "invalid",
          in_stock: "invalid"
        }]
      }

      expect {
        post :create, params: params
        expect(response.status).to eq(422)
      }.to change { DrugStock.count }.by(0)
      expected = {
        "status" => "invalid",
        "errors" => "Validation failed: In stock is not a number, Received is not a number"
      }
      expect(JSON.parse(response.body)).to eq(expected)
    end
  end
end
