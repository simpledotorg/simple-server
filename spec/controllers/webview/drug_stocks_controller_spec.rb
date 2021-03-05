require "rails_helper"

RSpec.describe Webview::DrugStocksController, type: :controller do
  before do
    Flipper.enable(:drug_stocks)
  end

  after do
    Flipper.disable(:drug_stocks)
  end

  fdescribe "GET #new" do
    let(:facility) { create(:facility) }

    it "renders 404 for anonymous users" do
      expect {
        get :new
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "denies access for users without sync approval" do
      user = create(:user, sync_approval_status: :denied)
      params = {
        access_token: user.access_token,
        facility_id: facility.id,
        user_id: user.id,
      }
      get :new, params: params
      expect(response).to be_forbidden
    end

    it "denies access for users with incorrect access token" do
      user = create(:user)
      params = {
        access_token: SecureRandom.hex(20),
        facility_id: facility.id,
        user_id: user.id,
      }
      get :new, params: params
      expect(response).to be_unauthorized
    end

  end

  describe "POST #create" do
    let(:power_user) { create(:user) }
    let(:facility_group) { create(:facility_group) }

    it "creates drug stock records and sends JSON success response" do
      facility = create(:facility, facility_group: power_user.facility.facility_group)
      protocol_drug = create(:protocol_drug, stock_tracked: true, protocol: facility.facility_group.protocol)
      params = {
        access_token: power_user.access_token,
        facility_id: facility.id,
        user_id: power_user.id,
        for_end_of_month: Date.today.strftime("%b-%Y"),
        drug_stocks: [{
          protocol_drug_id: protocol_drug.id,
          received: 10,
          in_stock: 20
        }]
      }

      expect {
        post :create, params: params
        expect(response).to be_redirect
      }.to change { DrugStock.count }.by(1)
      stock = DrugStock.find_by!(protocol_drug: protocol_drug)
      expect(stock.received).to eq(10)
    end

    it "sends error messages for invalid saves" do
      facility = create(:facility, facility_group: power_user.facility.facility_group)
      protocol_drug = create(:protocol_drug, stock_tracked: true, protocol: facility.facility_group.protocol)
      params = {
        access_token: power_user.access_token,
        facility_id: facility.id,
        user_id: power_user.id,
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
