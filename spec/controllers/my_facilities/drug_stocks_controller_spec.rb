require "rails_helper"

RSpec.describe MyFacilities::DrugStocksController, type: :controller do
  let(:facility_group_with_stock_tracked) { create(:facility_group) }
  let!(:facilities_with_stock_tracked) { create_list(:facility, 4, facility_group: facility_group_with_stock_tracked, facility_size: :small) }

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

  before do
    Flipper.enable(:drug_stocks)
  end

  after do
    Flipper.disable(:drug_stocks)
  end

  describe "GET #drug_stocks" do
    context "as power_user" do
      it "returns a success response" do
        create(:patient, registration_facility: facilities_with_stock_tracked.first)
        RefreshReportingViews.refresh_v2

        sign_in(power_user.email_authentication)
        get :drug_stocks, params: {}

        expect(response).to be_successful
      end

      it "only include facilities with tracked protocol drugs and registered patients or assigned patients or follow ups" do
        skip "failing on CI"
        patient = create(:patient, :hypertension, recorded_at: 2.months.ago, registration_facility: facilities_with_stock_tracked.first, assigned_facility: facilities_with_stock_tracked.second)
        create(:blood_pressure, patient: patient, recorded_at: 1.month.ago, facility: facilities_with_stock_tracked.third)
        RefreshReportingViews.refresh_v2

        sign_in(power_user.email_authentication)
        get :drug_stocks, params: {facility_group: facility_group_with_stock_tracked.slug}

        expect(assigns(:facilities)).to contain_exactly(facilities_with_stock_tracked.first, facilities_with_stock_tracked.second, facilities_with_stock_tracked.third)
        expect(assigns(:facilities)).not_to include(*facility_group.facilities, facilities_with_stock_tracked.fourth)
      end
    end

    context "as manager" do
      it "only include facilities with tracked protocol drugs and patients, and manager has access" do
        create(:patient, registration_facility: allowed_facility_for_manager)
        RefreshReportingViews.refresh_v2

        sign_in(manager.email_authentication)
        get :drug_stocks, params: {}

        expect(assigns(:facilities)).to contain_exactly(allowed_facility_for_manager)
      end
    end

    context "as viewer_reports_only" do
      it "only include facilities with tracked protocol drugs and patients, and viewer has access" do
        create(:patient, registration_facility: facilities_with_stock_tracked.first)
        create(:patient, registration_facility: facilities_with_stock_tracked.second)
        RefreshReportingViews.refresh_v2
        sign_in(report_viewer.email_authentication)
        get :drug_stocks, params: {}

        expect(assigns(:facilities)).to contain_exactly(facilities_with_stock_tracked.first, facilities_with_stock_tracked.second)
      end
    end

    context "uses the period reporting time zone to set display month" do
      before { sign_in(report_viewer.email_authentication) }

      it "sets previous month if not in last week of month" do
        Timecop.freeze("5 July 2021") do
          get :drug_stocks, params: {}

          expect(assigns(:for_end_of_month)).to eq(Time.use_zone("Asia/Kolkata") { Time.zone.parse("1 June 2021").end_of_month })
        end
      end

      it "sets current month if in last week of month" do
        Timecop.freeze("27 July 2021") do
          get :drug_stocks, params: {}

          expect(assigns(:for_end_of_month)).to eq(Time.use_zone("Asia/Kolkata") { Time.zone.parse("1 Jul 2021").end_of_month })
        end
      end

      it "sets selected month if a param is passed " do
        Timecop.freeze("27 July 2021") do
          get :drug_stocks, params: {for_end_of_month: "Jan-2021"}

          expect(assigns(:for_end_of_month)).to eq(Time.use_zone("Asia/Kolkata") { Time.zone.parse("1 Jan 2021").end_of_month })
        end
      end
    end
  end

  describe "GET #new" do
    context "as power_user" do
      let(:facility) { facility_group_with_stock_tracked.facilities.first }
      let(:facility_region) { facility.region }
      let(:params) {
        {
          region_id: facility_region.id,
          region_type: :facility,
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
        expect(assigns(:region)).to eq facility_region
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
          region_id: facility.region.id,
          region_type: :facility,
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

        params[:region_id] = disallowed_facility_for_manager.region.id

        get :new, params: params
        expect(response).to be_redirect
      end
    end

    context "as viewer_reports_only" do
      let(:facility) { facilities_with_stock_tracked.first }
      let(:params) {
        {
          region_id: facility.region.id,
          region_type: :facility,
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

    it "creates drug stock records and redirects successfully" do
      sign_in(power_user.email_authentication)

      expect { post :create, params: params, session: session }.to change { DrugStock.count }.by(1)
      expect(response).to redirect_to(redirect_url)
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

      expect(response).to redirect_to(redirect_url)
      expect(flash[:notice]).to eq "Saved drug stocks"
    end
  end
end
