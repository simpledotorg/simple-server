require "rails_helper"

RSpec.describe MyFacilities::DrugStocksController, type: :controller do
  let(:facility_group_with_stock_tracked) { create(:facility_group) }
  let!(:facilities_with_stock_tracked) { create_list(:facility, 3, facility_group: facility_group_with_stock_tracked) }
  let(:allowed_facility_for_manager) { facilities_with_stock_tracked.first }
  let(:disallowed_facility_for_manager) { facilities_with_stock_tracked.second }

  let(:protocol_drug) { create(:protocol_drug, stock_tracked: true, protocol: facility_group_with_stock_tracked.protocol) }
  let(:protocol_drug_2) { create(:protocol_drug, stock_tracked: true, protocol: facility_group_with_stock_tracked.protocol) }

  let(:facility_group) { create(:facility_group) }
  let(:facilities) { create_list(:facility, 3, facility_group: facility_group) }

  let(:power_user) { create(:admin, :power_user) }
  let(:manager) { create(:admin, :manager, :with_access, resource: allowed_facility_for_manager) }
  let(:report_viewer) { create(:admin, :viewer_reports_only, :with_access, resource: facility_group_with_stock_tracked) }

  render_views

  before do
    Flipper.enable(:drug_stocks)
  end

  after do
    Flipper.disable(:drug_stocks)
  end

  describe "GET #drug_stocks" do
    context "as power_user" do
      it "returns a success response" do
        sign_in(power_user.email_authentication)

        get :drug_stocks, params: {}
        expect(response).to be_successful
      end

      it "only include facilities with tracked protocol drugs" do
        sign_in(power_user.email_authentication)
        get :drug_stocks, params: {facility_group: facility_group_with_stock_tracked.slug}

        expect(assigns(:facilities)).to contain_exactly(*facilities_with_stock_tracked)
        expect(assigns(:facilities)).not_to include(*facility_group.facilities)
      end
    end

    context "as manager" do
      it "only include facilities with tracked protocol drugs, and manager has access" do
        sign_in(manager.email_authentication)
        get :drug_stocks, params: {}

        expect(assigns(:facilities)).to contain_exactly(allowed_facility_for_manager)
      end
    end

    context "as viewer_reports_only" do
      it "only include facilities with tracked protocol drugs, and viewer has access" do
        sign_in(report_viewer.email_authentication)
        get :drug_stocks, params: {}

        expect(assigns(:facilities)).to contain_exactly(*facilities_with_stock_tracked)
      end
    end
  end

  describe "GET #new" do
    context "as power_user" do
      let(:facility) { facility_group_with_stock_tracked.facilities.first }
      let(:params) {
        {
          facility_id: facility.id,
          for_end_of_month: Date.today.strftime("%b-%Y")
        }
      }

      it "returns a success response" do
        sign_in(power_user.email_authentication)

        get :new, params: params
        expect(response).to be_successful
      end

      it "returns no drug stocks if the data isn't available" do
        sign_in(power_user.email_authentication)

        get :new, params: params

        expect(response).to be_successful
        expect(assigns(:drug_stocks)).to be_empty
        expect(assigns(:facility)).to eq facility
      end

      it "returns the latest drug stocks in a facility for a given month" do
        sign_in(power_user.email_authentication)

        drug_stock_1 = create(:drug_stock, facility: facility, protocol_drug: protocol_drug)
        drug_stock_2 = create(:drug_stock, facility: facility, protocol_drug: protocol_drug_2)

        get :new, params: params

        expect(response).to be_successful

        drug_stock_hash = {}
        drug_stock_hash[protocol_drug.id] = drug_stock_1
        drug_stock_hash[protocol_drug_2.id] = drug_stock_2
        expect(assigns(:drug_stocks)).to eq drug_stock_hash
      end
    end

    context "as manager" do
      let(:facility) { allowed_facility_for_manager }
      let(:params) {
        {
          facility_id: facility.id,
          for_end_of_month: Date.today.strftime("%b-%Y")
        }
      }

      it "returns a success response for an allowed facility" do
        sign_in(manager.email_authentication)

        get :new, params: params
        expect(response).to be_successful
      end

      it "redirects for a disallowed facility" do
        sign_in(manager.email_authentication)

        get :new, params: params.merge(facility_id: disallowed_facility_for_manager.id)
        expect(response).to be_redirect
      end
    end

    context "as viewer_reports_only" do
      let(:facility) { facilities_with_stock_tracked.first }
      let(:params) {
        {
          facility_id: facility.id,
          for_end_of_month: Date.today.strftime("%b-%Y")
        }
      }

      it "redirects for facilities with view access" do
        sign_in(report_viewer.email_authentication)

        get :new, params: params
        expect(response).to be_redirect
      end
    end
  end

  describe "POST #create" do
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
