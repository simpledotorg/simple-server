require "rails_helper"

RSpec.describe Reports::RegionsController, type: :controller do
  let(:jan_2020) { Time.parse("January 1 2020") }
  let(:dec_2019_period) { Period.month(Date.parse("December 2019")) }
  let(:organization) { FactoryBot.create(:organization) }
  let(:cvho) { create(:admin, :manager, :with_access, resource: organization, organization: organization) }
  let(:call_center_user) { create(:admin, :call_center, full_name: "call_center") }
  let(:facility_group_1) { FactoryBot.create(:facility_group, name: "facility_group_1", organization: organization) }
  let(:facility_1) { FactoryBot.create(:facility, name: "facility_1", facility_group: facility_group_1) }

  describe "show" do
    render_views

    before do
      @facility_group = create(:facility_group, organization: organization)
      @facility = create(:facility, name: "CHC Barnagar", facility_group: @facility_group)
      @facility_region = @facility.region
    end

    it "redirects if matching region slug not found" do
      sign_in(cvho.email_authentication)
      get :show, params: {id: "String-unknown", report_scope: "bad-report_scope"}
      expect(flash[:alert]).to eq("You are not authorized to perform this action.")
      expect(response).to be_redirect
    end

    it "redirects if user does not have proper access to org" do
      district_official = create(:admin, :viewer_reports_only, :with_access, resource: @facility_group)

      sign_in(district_official.email_authentication)
      get :show, params: {id: @facility_group.organization.slug, report_scope: "organization"}
      expect(flash[:alert]).to eq("You are not authorized to perform this action.")
      expect(response).to be_redirect
    end

    it "redirects if user does not have authorization to region" do
      other_fg = create(:facility_group, name: "other facility group")
      other_fg.facilities << build(:facility, name: "other facility")
      user = create(:admin, :viewer_reports_only, :with_access, resource: other_fg)

      sign_in(user.email_authentication)
      get :show, params: {id: @facility_region.slug, report_scope: "facility"}
      expect(flash[:alert]).to eq("You are not authorized to perform this action.")
      expect(response).to be_redirect
    end

    it "finds a district region if it has different slug compared to the facility group" do
      other_fg = create(:facility_group, name: "other facility group", organization: organization)
      region = other_fg.region
      slug = region.slug
      region.update!(slug: "#{slug}-district")
      expect(region.slug).to_not eq(other_fg.slug)
      other_fg.facilities << build(:facility, name: "other facility")
      user = create(:admin, :viewer_reports_only, :with_access, resource: other_fg)

      sign_in(user.email_authentication)
      get :show, params: {id: region.slug, report_scope: "district"}
      expect(response).to be_successful
    end

    it "renders successfully for an organization" do
      other_fg = create(:facility_group, name: "other facility group", organization: organization)
      create(:facility, name: "other facility", facility_group: other_fg)
      user = create(:admin, :viewer_reports_only, :with_access, resource: other_fg)

      sign_in(user.email_authentication)
      get :show, params: {id: organization.slug, report_scope: "organization"}
    end

    it "renders successfully if report viewer has access to region" do
      other_fg = create(:facility_group, name: "other facility group", organization: organization)
      create(:facility, name: "other facility", facility_group: other_fg)
      user = create(:admin, :viewer_reports_only, :with_access, resource: other_fg)

      sign_in(user.email_authentication)
      get :show, params: {id: other_fg.region.slug, report_scope: "district"}
      expect(response).to be_successful
    end

    it "returns period info for every month" do
      Timecop.freeze("June 1 2020") do
        sign_in(cvho.email_authentication)
        get :show, params: {id: @facility.facility_group.region.slug, report_scope: "district"}
      end
      data = assigns(:data)
      period_hash = {
        name: "Dec-2019",
        bp_control_start_date: "1-Oct-2019",
        bp_control_end_date: "31-Dec-2019",
        ltfu_since_date: "31-Dec-2018",
        bp_control_registration_date: "30-Sep-2019"
      }
      expect(data[:period_info][dec_2019_period]).to eq(period_hash)
    end

    it "returns period info for current month" do
      today = Date.current
      Timecop.freeze(today) do
        patient = create(:patient, registration_facility: @facility, recorded_at: 2.months.ago)
        create(:bp_with_encounter, :under_control, recorded_at: Time.current.yesterday, patient: patient, facility: @facility)
        refresh_views
        sign_in(cvho.email_authentication)
        get :show, params: {id: @facility.facility_group.slug, report_scope: "district"}
      end
      data = assigns(:data)
      expect(data[:period_info][Period.month(today.beginning_of_month)]).to_not be_nil
    end

    it "retrieves district data" do
      patient = create(:patient, registration_facility: @facility, recorded_at: jan_2020.advance(months: -4))
      create(:bp_with_encounter, :under_control, recorded_at: jan_2020.advance(months: -1), patient: patient, facility: @facility)
      create(:bp_with_encounter, :hypertensive, recorded_at: jan_2020, facility: @facility)
      refresh_views

      Timecop.freeze("June 1 2020") do
        sign_in(cvho.email_authentication)
        get :show, params: {id: @facility.facility_group.slug, report_scope: "district"}
      end
      expect(response).to be_successful
      data = assigns(:data)
      expect(data[:controlled_patients].size).to eq(10) # sanity check
      expect(data[:controlled_patients][dec_2019_period]).to eq(1)
    end

    it "retrieves facility data" do
      Time.parse("January 1 2020")
      patient = create(:patient, registration_facility: @facility, recorded_at: jan_2020.advance(months: -4))
      create(:bp_with_encounter, :under_control, recorded_at: jan_2020.advance(months: -1), patient: patient, facility: @facility)
      create(:bp_with_encounter, :hypertensive, recorded_at: jan_2020, facility: @facility)
      refresh_views

      Timecop.freeze("June 1 2020") do
        sign_in(cvho.email_authentication)
        get :show, params: {id: @facility_region.slug, report_scope: "facility"}
      end
      expect(response).to be_successful
      data = assigns(:data)
      expect(data[:controlled_patients].size).to eq(10) # sanity check
      expect(data[:controlled_patients][Date.parse("Dec 2019").to_period]).to eq(1)
    end

    it "retrieves block data" do
      patient_2 = create(:patient, registration_facility: @facility, recorded_at: "June 01 2019 00:00:00 UTC", registration_user: cvho)
      create(:bp_with_encounter, :hypertensive, recorded_at: "Feb 2020", facility: @facility, patient: patient_2, user: cvho)

      patient_1 = create(:patient, registration_facility: @facility, recorded_at: "September 01 2019 00:00:00 UTC", registration_user: cvho)
      create(:bp_with_encounter, :under_control, recorded_at: "December 10th 2019", patient: patient_1, facility: @facility, user: cvho)
      create(:bp_with_encounter, :hypertensive, recorded_at: jan_2020, facility: @facility, user: cvho)

      refresh_views

      block = @facility.region.block_region
      Timecop.freeze("June 1 2020") do
        sign_in(cvho.email_authentication)
        get :show, params: {id: block.to_param, report_scope: "block"}
      end
      expect(response).to be_successful
      data = assigns(:data)

      expect(data[:registrations][Period.month("June 2019")]).to eq(1)
      expect(data[:registrations][Period.month("September 2019")]).to eq(1)
      expect(data[:controlled_patients][Period.month("Dec 2019")]).to eq(1)
      expect(data[:uncontrolled_patients][Period.month("Feb 2020")]).to eq(1)
      expect(data[:uncontrolled_patients_rate][Period.month("Feb 2020")]).to eq(50)
      expect(data[:missed_visits][Period.month("September 2019")]).to eq(1)
      expect(data[:missed_visits][Period.month("May 2020")]).to eq(2)
    end

    it "works when a user requests data just before the earliest registration date" do
      patient = create(:patient, registration_facility: @facility, recorded_at: jan_2020.advance(months: -4))
      create(:bp_with_encounter, :under_control, recorded_at: jan_2020.advance(months: -1), patient: patient, facility: @facility)
      create(:bp_with_encounter, :hypertensive, recorded_at: jan_2020, facility: @facility)
      refresh_views
      one_month_before = patient.recorded_at.advance(months: -1)

      sign_in(cvho.email_authentication)
      get :show, params: {id: @facility_region.slug, report_scope: "facility",
                          period: {type: :month, value: one_month_before}}
      expect(response).to be_successful
      data = assigns(:data)
      expect(data[:controlled_patients]).to eq({})
      expect(data[:period_info]).to eq({})
    end

    it "works for very old dates" do
      patient = create(:patient, registration_facility: @facility, recorded_at: jan_2020.advance(months: -4))
      create(:bp_with_encounter, :under_control, recorded_at: jan_2020.advance(months: -1), patient: patient, facility: @facility)
      refresh_views
      ten_years_ago = patient.recorded_at.advance(years: -10)

      sign_in(cvho.email_authentication)
      get :show, params: {id: @facility_region.slug, report_scope: "facility",
                          period: {type: :month, value: ten_years_ago}}
      expect(response).to be_successful
      data = assigns(:data)
      expect(data[:controlled_patients]).to eq({})
      expect(data[:period_info]).to eq({})
    end

    it "works for far future dates" do
      patient = create(:patient, registration_facility: @facility, recorded_at: jan_2020.advance(months: -4))
      create(:bp_with_encounter, :under_control, recorded_at: jan_2020.advance(months: -1), patient: patient, facility: @facility)
      refresh_views
      ten_years_from_now = patient.recorded_at.advance(years: -10)

      sign_in(cvho.email_authentication)
      get :show, params: {id: @facility_region.slug, report_scope: "facility",
                          period: {type: :month, value: ten_years_from_now}}
      expect(response).to be_successful
      data = assigns(:data)
      expect(data[:controlled_patients]).to eq({})
      expect(data[:period_info]).to eq({})
    end
  end

  describe "index" do
    render_views

    before do
      @facility_group = create(:facility_group, organization: organization)
      @facility_1 = create(:facility, name: "Facility 1", block: "Block 1", facility_group: @facility_group)
      @facility_2 = create(:facility, name: "Facility 2", block: "Block 1", facility_group: @facility_group)
      @block = @facility_1.block_region
    end

    it "loads nothing if user has no access to any regions" do
      sign_in(call_center_user.email_authentication)
      get :index
      expect(assigns[:accessible_regions]).to eq({})
      expect(response).to be_successful
    end

    it "only loads districts the user has access to" do
      sign_in(cvho.email_authentication)
      get :index
      expect(response).to be_successful
      facility_regions = [@facility_1.region, @facility_2.region]
      org_region = organization.region
      state_region = @facility_1.region.state_region
      expect(assigns[:accessible_regions].keys).to eq([org_region])
      expect(assigns[:accessible_regions][org_region].keys).to match_array(org_region.state_regions)
      expect(assigns[:accessible_regions].dig(org_region, state_region, @facility_group.region, @block.region)).to match_array(facility_regions)
    end
  end

  describe "details" do
    render_views

    before do
      @facility_group = create(:facility_group, organization: organization)
      @facility = create(:facility, name: "CHC Barnagar", facility_group: @facility_group)
    end

    it "is successful for an organization" do
      patient = create(:patient, registration_facility: @facility, recorded_at: jan_2020.advance(months: -1))
      create(:bp_with_encounter, :under_control, recorded_at: jan_2020.advance(months: -1), patient: patient, facility: @facility)
      create(:bp_with_encounter, :hypertensive, recorded_at: jan_2020, facility: @facility)
      refresh_views

      org = @facility_group.organization

      Timecop.freeze("June 1 2020") do
        sign_in(cvho.email_authentication)
        get :details, params: {id: org.slug, report_scope: "organization"}
      end
      expect(response).to be_successful
    end

    it "is successful for a district" do
      patient = create(:patient, registration_facility: @facility, recorded_at: jan_2020.advance(months: -1))
      create(:bp_with_encounter, :under_control, recorded_at: jan_2020.advance(months: -1), patient: patient, facility: @facility)
      create(:bp_with_encounter, :hypertensive, recorded_at: jan_2020, facility: @facility)
      refresh_views

      Timecop.freeze("June 1 2020") do
        sign_in(cvho.email_authentication)
        get :details, params: {id: @facility.facility_group.region.slug, report_scope: "district"}
      end
      expect(response).to be_successful
    end

    it "is successful for a block" do
      patient_2 = create(:patient, registration_facility: @facility, recorded_at: "June 01 2019 00:00:00 UTC", registration_user: cvho)
      create(:bp_with_encounter, :hypertensive, recorded_at: "Feb 2020", facility: @facility, patient: patient_2, user: cvho)

      patient_1 = create(:patient, registration_facility: @facility, recorded_at: "September 01 2019 00:00:00 UTC", registration_user: cvho)
      create(:bp_with_encounter, :under_control, recorded_at: "December 10th 2019", patient: patient_1, facility: @facility, user: cvho)
      create(:bp_with_encounter, :hypertensive, recorded_at: jan_2020, facility: @facility, user: cvho)

      refresh_views

      block = @facility.region.block_region

      Timecop.freeze("June 1 2020") do
        sign_in(cvho.email_authentication)
        get :details, params: {id: block.slug, report_scope: "block"}
      end
      expect(response).to be_successful
    end

    it "is successful for a facility" do
      patient = create(:patient, registration_facility: @facility, recorded_at: jan_2020.advance(months: -1))
      create(:bp_with_encounter, :under_control, recorded_at: jan_2020.advance(months: -1), patient: patient, facility: @facility)
      create(:bp_with_encounter, :hypertensive, recorded_at: jan_2020, facility: @facility)
      refresh_views

      Timecop.freeze("June 1 2020") do
        sign_in(cvho.email_authentication)
        get :details, params: {id: @facility.region.slug, report_scope: "facility"}
      end
      expect(response).to be_successful
    end

    it "renders period hash info" do
      patient = create(:patient, registration_facility: @facility, recorded_at: jan_2020.advance(months: -1))
      create(:bp_with_encounter, :under_control, recorded_at: jan_2020.advance(months: -1), patient: patient, facility: @facility)
      create(:bp_with_encounter, :hypertensive, recorded_at: jan_2020, facility: @facility)
      refresh_views

      Timecop.freeze("June 1 2020") do
        sign_in(cvho.email_authentication)
        get :details, params: {id: @facility.region.slug, report_scope: "facility"}
        period_info = assigns(:chart_data)[:ltfu_trend][:period_info]
        expect(period_info.keys.size).to eq(24)
        period_info.each do |period, hsh|
          expect(hsh).to eq(period.to_hash)
        end
      end
    end
  end

  describe "cohort" do
    render_views

    before do
      @facility_group = create(:facility_group, organization: organization)
      @facility = create(:facility, name: "CHC Barnagar", facility_group: @facility_group)
    end

    it "retrieves monthly cohort data by default" do
      patient = create(:patient, registration_facility: @facility, registration_user: cvho, recorded_at: jan_2020.advance(months: -1))
      create(:bp_with_encounter, :under_control, recorded_at: jan_2020.advance(months: -1), patient: patient, facility: @facility)
      create(:bp_with_encounter, :hypertensive, recorded_at: jan_2020, facility: @facility)
      refresh_views

      Timecop.freeze("June 1 2020") do
        sign_in(cvho.email_authentication)
        get :cohort, params: {id: @facility.facility_group.slug, report_scope: "district"}
      end
      expect(response).to be_successful
      data = assigns(:cohort_data)
      dec_cohort = data.find { |hsh| hsh["patients_registered"] == "Dec-2019" }
      expect(dec_cohort["registered"]).to eq(1)
    end

    it "can retrieve quarterly cohort data" do
      patient = create(:patient, registration_facility: @facility, registration_user: cvho, recorded_at: jan_2020.advance(months: -2))
      create(:bp_with_encounter, :under_control, recorded_at: jan_2020 + 1.day, patient: patient, facility: @facility)
      refresh_views

      Timecop.freeze("June 1 2020") do
        sign_in(cvho.email_authentication)
        get :cohort, params: {id: @facility.facility_group.slug, report_scope: "district", period: {type: "quarter", value: "Q2-2020"}}
        expect(response).to be_successful
        data = assigns(:cohort_data)
        expect(data.size).to eq(6)
        q2_data = data[1]
        expect(q2_data["results_in"]).to eq("Q1-2020")
        expect(q2_data["registered"]).to eq(1)
        expect(q2_data["controlled"]).to eq(1)
      end
    end

    it "can retrieve quarterly cohort data for a new facility with no data" do
      refresh_views

      Timecop.freeze("June 1 2020") do
        sign_in(cvho.email_authentication)

        get :cohort, params: {id: @facility.facility_group.slug, report_scope: "district", period: {type: "quarter", value: "Q2-2020"}}
        expect(response).to be_successful
        data = assigns(:cohort_data)
        expect(data.size).to eq(6)
        q2_data = data[1]
        expect(q2_data["results_in"]).to eq("Q1-2020")
        expect(q2_data["period"]).to eq(Period.quarter("Q1-2020"))
        expect(q2_data["registered"]).to be_nil
        expect(q2_data["controlled"]).to be_nil
      end
    end
  end

  describe "download" do
    render_views

    before do
      @facility_group = create(:facility_group, organization: organization)
      @facility = create(:facility, name: "CHC Barnagar", facility_group: @facility_group)
    end

    it "retrieves cohort data for a facility" do
      patient = create(:patient, registration_facility: @facility, recorded_at: jan_2020.advance(months: -1))
      create(:bp_with_encounter, :under_control, recorded_at: jan_2020.advance(months: -1), patient: patient, facility: @facility)
      create(:bp_with_encounter, :hypertensive, recorded_at: jan_2020, facility: @facility)
      refresh_views

      result = nil
      Timecop.freeze("June 1 2020") do
        sign_in(cvho.email_authentication)
        result = get :download, params: {id: @facility.slug, report_scope: "facility", period: "month", format: "csv"}
      end
      expect(response).to be_successful
      expect(response.body).to include("CHC Barnagar Monthly Cohort Report")
      expect(response.headers["Content-Disposition"]).to include('filename="facility-monthly-cohort-report_CHC-Barnagar')
      expect(result).to render_template("cohort.csv.erb")
    end

    it "retrieves cohort data for a facility group" do
      facility_group = @facility.facility_group
      patient = create(:patient, registration_facility: @facility, recorded_at: jan_2020.advance(months: -1))
      create(:bp_with_encounter, :under_control, recorded_at: jan_2020.advance(months: -1), patient: patient, facility: @facility)
      create(:bp_with_encounter, :hypertensive, recorded_at: jan_2020, facility: @facility)
      refresh_views

      result = nil
      Timecop.freeze("June 1 2020") do
        sign_in(cvho.email_authentication)
        result = get :download, params: {id: facility_group.slug, report_scope: "district", period: "quarter", format: "csv"}
      end
      expect(response).to be_successful
      expect(response.body).to include("#{facility_group.name} Quarterly Cohort Report")
      expect(response.headers["Content-Disposition"]).to include('filename="district-quarterly-cohort-report_')
      expect(result).to render_template("facility_group_cohort.csv.erb")
    end
  end

  describe "monthly_district_report" do
    before do
      @facility_group = create(:facility_group, organization: organization)
      @facility = create(:facility, facility_group: @facility_group)
    end

    it "retrieves the monthly district report" do
      Flipper.enable(:monthly_district_report)

      district = @facility_group.region
      refresh_views

      files = []
      Timecop.freeze("June 1 2020") do
        sign_in(cvho.email_authentication)
        get :monthly_district_report, params: {id: district.slug, report_scope: "district", format: "zip"}
      end
      expect(response).to be_successful

      Zip::File.open_buffer(response.body) do |zip|
        zip.map do |entry|
          files << entry.name
        end
      end

      expect(files).to match_array(%w[facility_data.csv block_data.csv district_data.csv])
      expect(response.headers["Content-Disposition"]).to include("filename=\"monthly-district-report-#{district.slug}-jun-2020.zip\"")
    end
  end

  describe "#whatsapp_graphics" do
    render_views

    before do
      @facility_group = create(:facility_group, organization: organization)
      @facility = create(:facility, name: "CHC Barnagar", facility_group: @facility_group)
      sign_in(cvho.email_authentication)
    end

    describe "html requested" do
      it "renders graphics_header partial" do
        get :whatsapp_graphics, format: :html, params: {id: @facility.region.slug, report_scope: "facility"}

        expect(response).to be_ok
        expect(response).to render_template("shared/graphics/_graphics_partial")
      end
    end

    describe "png requested" do
      it "renders the image template for downloading" do
        get :whatsapp_graphics, format: :png, params: {id: @facility_group.region.slug, report_scope: "district"}

        expect(response).to be_ok
        expect(response).to render_template("shared/graphics/image_template")
      end
    end
  end

  describe "#monthly_district_data_report" do
    let(:facility_group) { create(:facility_group, organization: organization) }
    let(:facility) { create(:facility, facility_group: facility_group) }
    let(:region) { facility.region.district_region }

    it "returns 401 when user is not authorized" do
      facility

      get :monthly_district_data_report, params: {id: region.slug, report_scope: "district", format: "csv"}
      expect(response.status).to eq(401)
    end

    it "returns 302 found with invalid region" do
      facility
      sign_in(cvho.email_authentication)

      get :monthly_district_data_report, params: {id: "not-found", report_scope: "district", format: "csv"}
      expect(response.status).to eq(302)
    end

    it "returns 302 if region is not district" do
      facility
      sign_in(cvho.email_authentication)

      get :monthly_district_data_report, params: {id: facility.slug, report_scope: "district", format: "csv"}
      expect(response.status).to eq(302)
    end

    it "calls csv service and returns 200 with csv data" do
      Timecop.freeze("June 15th 2020") do
        facility
        sign_in(cvho.email_authentication)

        expect_any_instance_of(MonthlyDistrictDataService).to receive(:report).and_call_original
        get :monthly_district_data_report, params: {id: region.slug, report_scope: "district", format: "csv"}
        expect(response.status).to eq(200)
        expect(response.body).to include("Monthly facility data for #{region.name} #{Date.current.strftime("%B %Y")}")
        report_date = Date.current.strftime("%b-%Y").downcase
        expected_filename = "monthly-facility-data-#{region.slug}-#{report_date}.csv"
        expect(response.headers["Content-Disposition"]).to include(%(filename="#{expected_filename}"))
      end
    end

    it "passes the provided period to the csv service" do
      facility
      sign_in(cvho.email_authentication)

      period = Period.month("July 2018")
      expect(MonthlyDistrictDataService).to receive(:new).with(region, period).and_call_original
      get :monthly_district_data_report,
        params: {id: region.slug, report_scope: "district", format: "csv", period: period.value}
    end
  end

  describe "#monthly_state_data_report" do
    let(:facility_group) { create(:facility_group, organization: organization) }
    let(:facility) { create(:facility, facility_group: facility_group) }
    let(:region) { facility.region.state_region }

    it "returns 401 when user is not authorized" do
      facility

      get :monthly_state_data_report, params: {id: region.slug, report_scope: "state", format: "csv"}
      expect(response.status).to eq(401)
    end

    it "returns 302 found with invalid region" do
      facility
      sign_in(cvho.email_authentication)

      get :monthly_state_data_report, params: {id: "not-found", report_scope: "state", format: "csv"}
      expect(response.status).to eq(302)
    end

    it "returns 302 if region is not state" do
      facility
      sign_in(cvho.email_authentication)

      get :monthly_state_data_report, params: {id: facility.slug, report_scope: "state", format: "csv"}
      expect(response.status).to eq(302)
    end

    it "calls csv service and returns 200 with csv data" do
      Timecop.freeze("June 15th 2020") do
        facility
        sign_in(cvho.email_authentication)

        expect_any_instance_of(MonthlyStateDataService).to receive(:report).and_call_original
        get :monthly_state_data_report, params: {id: region.slug, report_scope: "state", format: "csv"}
        expect(response.status).to eq(200)
        expect(response.body).to include("Monthly district data for #{region.name} #{Date.current.strftime("%B %Y")}")
        report_date = Date.current.strftime("%b-%Y").downcase
        expected_filename = "monthly-district-data-#{region.slug}-#{report_date}.csv"
        expect(response.headers["Content-Disposition"]).to include(%(filename="#{expected_filename}"))
      end
    end

    it "passes the provided period to the csv service" do
      facility
      sign_in(cvho.email_authentication)

      period = Period.month("July 2018")
      expect(MonthlyStateDataService).to receive(:new).with(region, period).and_call_original
      get :monthly_state_data_report,
        params: {id: region.slug, report_scope: "state", format: "csv", period: period.value}
    end
  end
end
