require "rails_helper"

RSpec.describe Api::DrugStocksController, type: :controller do
  before do
    Flipper.enable(:drug_stocks)
  end

  after do
    Flipper.disable(:drug_stocks)
  end

  xdescribe "POST #create" do
    let(:redirect_url) { "report_url_with_filters" }
    let(:session) { {report_url_with_filters: redirect_url} }
    let(:params) {
      {
        facility_id: facility_group_with_stock_tracked.facilities.first.id,
        for_end_of_month: Date.today.strftime("%b-%Y"),
        drug_stocks: [{
          protocol_drug_id: protocol_drug.id,
          received: 10,
          in_stock: 20
        }]
      }
    }

    it "creates drug stock records and redirects successfully" do
      sign_in(power_user.email_authentication)

      expect { post :create, params: params, session: session }.to change { DrugStock.count }.by(1)
      expect(response).to redirect_to(redirect_url + "?force_cache=true")
      expect(flash[:notice]).to eq "Saved drug stocks"
    end

    it "shows an error message if params are invalid" do
      sign_in(power_user.email_authentication)

      expect {
        post :create,
          params: params.merge(drug_stocks: [{protocol_drug_id: protocol_drug.id,
                                              received: "ten",
                                              in_stock: nil}]),
          session: session
      }.not_to change { DrugStock.count }

      expect(response).to redirect_to(redirect_url)
      expect(flash[:alert]).to eq "Something went wrong, Drug Stocks were not saved."
    end

    it "allows saving empty drug stock values" do
      sign_in(power_user.email_authentication)

      expect {
        post :create,
          params: params.merge(drug_stocks: [{protocol_drug_id: protocol_drug.id,
                                              in_stock: nil,
                                              received: nil}]),
          session: session
      }.to change { DrugStock.count }.by(1)

      expect(response).to redirect_to(redirect_url + "?force_cache=true")
      expect(flash[:notice]).to eq "Saved drug stocks"
    end
  end
end