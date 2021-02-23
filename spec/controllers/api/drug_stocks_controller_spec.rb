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

    fit "creates drug stock records and redirects successfully" do
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
      expect(flash[:notice]).to eq "Saved drug stocks"
    end
  end
end