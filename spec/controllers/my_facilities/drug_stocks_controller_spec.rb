require "rails_helper"

RSpec.describe MyFacilities::DrugStocksController, type: :controller do
  let!(:facility_group_with_stock_tracked) { create(:facility_group) }
  let!(:facilities_with_stock_tracked) { create_list(:facility, 3, facility_group: facility_group_with_stock_tracked) }
  let!(:protocol_drug) { create(:protocol_drug, stock_tracked: true, protocol: facility_group_with_stock_tracked.protocol) }
  let!(:protocol_drug_2) { create(:protocol_drug, stock_tracked: true, protocol: facility_group_with_stock_tracked.protocol) }

  let!(:facility_group) { create(:facility_group) }
  let!(:facilities) { create_list(:facility, 3, facility_group: facility_group) }

  let!(:power_user) { create(:admin, :power_user) }

  render_views

  before do
    sign_in(power_user.email_authentication)
    Flipper.enable(:drug_stocks)
  end

  after do
    Flipper.disable(:drug_stocks)
  end

  describe "GET #index" do
    it "returns a success response" do
      get :index, params: {}
    end

    it "only include facilities with tracked protocol drugs" do
      get :index, params: {}

      expect(response).to be_successful
      expect(assigns(:facilities)).to include(*facility_group_with_stock_tracked.facilities)
      expect(assigns(:facilities)).not_to include(*facility_group.facilities)
    end
  end

  describe "POST #create" do
    let(:params) {
      {
        facility_id: facility_group_with_stock_tracked.facilities.first.id,
        for_end_of_month: Date.today.strftime("%B %Y"),
        drug_stocks: [{
          protocol_drug_id: protocol_drug.id,
          received: 10,
          in_stock: 20
        }]
      }
    }

    it "creates drug stock records and redirects successfully" do
      expect { post :create, params: params }.to change { DrugStock.count }.by(1)
      expect(response).to redirect_to(my_facilities_drug_stocks_path)
      expect(flash[:notice]).to eq "Saved drug stocks"
    end

    it "shows an error message if params are invalid" do
      expect { post :create, params: params.merge(facility_id: nil) }.not_to change { DrugStock.count }

      expect(response).to redirect_to(my_facilities_drug_stocks_path)
      expect(flash[:alert]).to eq "Something went wrong, Drug Stocks were not saved."
    end

    it "redirects without an error message if no valid drug stocks are submitted" do
      expect {
        post :create, params: params.merge(drug_stocks: [{protocol_drug_id: protocol_drug.id,
                                                          in_stock: nil,
                                                          received: nil}])
      }.not_to change { DrugStock.count }

      expect(response).to redirect_to(my_facilities_drug_stocks_path)
      expect(flash[:notice]).to be_nil
    end
  end
end
