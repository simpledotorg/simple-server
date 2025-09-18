require "rails_helper"

RSpec.describe MyFacilities::DrugStocksController, type: :controller do
  let(:facility_group_with_stock_tracked) { create(:facility_group) }
  let!(:facilities_with_stock_tracked) do
    create_list(:facility, 4, facility_group: facility_group_with_stock_tracked, facility_size: :small)
  end

  let(:allowed_facility_for_manager) { facilities_with_stock_tracked.first }
  let(:disallowed_facility_for_manager) { facilities_with_stock_tracked.second }

  let(:protocol_drug) { create(:protocol_drug, stock_tracked: true, protocol: facility_group_with_stock_tracked.protocol) }
  let(:protocol_drug_2) { create(:protocol_drug, stock_tracked: true, protocol: facility_group_with_stock_tracked.protocol) }

  let(:facility_group) { create(:facility_group) }
  let(:facilities) { create_list(:facility, 3, facility_group: facility_group, facility_size: :large) }

  let(:power_user) { create(:admin, :power_user) }
  let(:manager) { create(:admin, :manager, :with_access, resource: allowed_facility_for_manager) }
  let(:report_viewer) { create(:admin, :viewer_reports_only, :with_access, resource: facility_group_with_stock_tracked) }

  render_views

  before { Flipper.enable(:drug_stocks) }
  after { Flipper.disable(:drug_stocks) }

  describe "GET #drug_stocks" do
    context "as power_user" do
      before { sign_in(power_user.email_authentication) }

      context "overview enabled" do
        before do
          allow(controller).to receive(:all_district_overview_enabled?).and_return(true)
          allow(controller).to receive(:accessible_organization_facilities)
            .and_return(Facility.where(id: facilities_with_stock_tracked.map(&:id)))
          allow(controller).to receive(:accessible_organization_districts)
            .and_return([facility_group_with_stock_tracked])
          allow(controller).to receive(:drug_stock_enabled_facilities)
            .and_return(Facility.where(id: facilities_with_stock_tracked.map(&:id)))

          create(:patient, registration_facility: facilities_with_stock_tracked.first)
          RefreshReportingViews.refresh_v2
        end

        it "assigns @all_facilities and @district_reports" do
          get :drug_stocks, params: {}
          expect(assigns(:all_facilities)).to match_array(facilities_with_stock_tracked)
          expect(assigns(:district_reports)).to be_a(Hash)
          expect(assigns(:district_reports).keys).to match_array([facility_group_with_stock_tracked])
        end
      end

      context "overview not enabled" do
        before do
          allow(controller).to receive(:all_district_overview_enabled?).and_return(false)
          allow(controller).to receive(:drug_stock_enabled_facilities)
            .and_return(Facility.where(id: facilities_with_stock_tracked.map(&:id)))

          create(:patient, registration_facility: facilities_with_stock_tracked.first)
          RefreshReportingViews.refresh_v2
        end

        it "assigns @all_facilities and @report" do
          get :drug_stocks, params: {}
          expect(assigns(:all_facilities)).to include(facilities_with_stock_tracked.first)
          expect(assigns(:report)).to be_present
        end
      end

      context "CSV response" do
        before do
          allow(DrugStocksReportExporter).to receive(:csv).and_return("id,drug_name,stock\n1,Paracetamol,10")
          allow(DrugConsumptionReportExporter).to receive(:csv).and_return("id,drug_name,consumption\n1,Paracetamol,5")
        end

        it "returns CSV for drug_stocks" do
          get :drug_stocks, params: {}, format: :csv
          expect(response.content_type).to eq "text/csv"
        end

        it "returns CSV for drug_consumption" do
          get :drug_consumption, params: {}, format: :csv
          expect(response.content_type).to eq "text/csv"
        end
      end
    end

    context "as manager" do
      it "only includes facilities manager has access to" do
        create(:patient, registration_facility: allowed_facility_for_manager)
        RefreshReportingViews.refresh_v2

        sign_in(manager.email_authentication)
        get :drug_stocks, params: {}
        expect(assigns(:facilities)).to contain_exactly(allowed_facility_for_manager)
      end
    end

    context "as viewer_reports_only" do
      it "only includes facilities viewer has access to" do
        create(:patient, registration_facility: facilities_with_stock_tracked.first)
        create(:patient, registration_facility: facilities_with_stock_tracked.second)
        RefreshReportingViews.refresh_v2

        sign_in(report_viewer.email_authentication)
        get :drug_stocks, params: {}
        expect(assigns(:facilities)).to contain_exactly(facilities_with_stock_tracked.first, facilities_with_stock_tracked.second)
      end
    end
  end

  describe "GET #new" do
    let(:facility) { facility_group_with_stock_tracked.facilities.first }
    let(:params) {
      {
        region_id: facility.region.id,
        region_type: :facility,
        for_end_of_month: Date.today.strftime("%b-%Y")
      }
    }

    context "as power_user" do
      before { sign_in(power_user.email_authentication) }

      it "assigns latest drug stocks" do
        drug_stock_1 = create(:drug_stock, facility: facility, protocol_drug: protocol_drug)
        drug_stock_2 = create(:drug_stock, facility: facility, protocol_drug: protocol_drug_2)

        get :new, params: params
        expect(assigns(:drug_stocks)).to eq({
          protocol_drug.id => drug_stock_1,
          protocol_drug_2.id => drug_stock_2
        })
      end
    end

    context "as manager" do
      let(:params) {
        {
          region_id: allowed_facility_for_manager.region.id,
          region_type: :facility,
          for_end_of_month: Date.today.strftime("%b-%Y")
        }
      }

      it "allows access for allowed facility" do
        sign_in(manager.email_authentication)
        get :new, params: params
        expect(response).to be_successful
      end

      it "redirects for disallowed facility" do
        sign_in(manager.email_authentication)
        params[:region_id] = disallowed_facility_for_manager.region.id
        get :new, params: params
        expect(response).to be_redirect
      end
    end

    context "as viewer_reports_only" do
      it "redirects" do
        sign_in(report_viewer.email_authentication)
        get :new, params: params
        expect(response).to be_redirect
      end
    end
  end

  describe "POST #create" do
    let(:redirect_url) { "report_url_with_filters" }
    let(:session) { {report_url_with_filters: redirect_url} }
    let(:facility) { facility_group_with_stock_tracked.facilities.first }
    let(:params) {
      {
        region_id: facility.region.id,
        region_type: :facility,
        for_end_of_month: Date.today.strftime("%b-%Y"),
        drug_stocks: [{
          protocol_drug_id: protocol_drug.id,
          received: 10,
          in_stock: 20
        }]
      }
    }

    before { sign_in(power_user.email_authentication) }

    it "creates drug stock records and redirects successfully" do
      expect {
        post :create, params: params, session: session
      }.to change { DrugStock.count }.by(1)
      expect(response).to redirect_to(redirect_url)
      expect(flash[:notice]).to eq "Saved drug stocks"
    end

    it "shows an error message if params are invalid" do
      expect {
        post :create,
          params: params.merge(drug_stocks: [{protocol_drug_id: protocol_drug.id, received: "ten", in_stock: nil}]),
          session: session
      }.not_to change { DrugStock.count }
      expect(response).to redirect_to(redirect_url)
      expect(flash[:alert]).to eq "Something went wrong, Drug Stocks were not saved."
    end
  end
end
