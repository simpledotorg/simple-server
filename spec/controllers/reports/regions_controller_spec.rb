require "rails_helper"

RSpec.describe Reports::RegionsController, type: :controller do
  let(:jan_2020) { Time.parse("January 1 2020") }
  let(:dec_2019_period) { Period.month(Date.parse("December 2019")) }
  let(:organization) { FactoryBot.create(:organization) }
  let(:cvho) { create(:admin, :manager, :with_access, resource: organization, organization: organization) }
  let(:call_center_user) { create(:admin, :call_center, full_name: "call_center") }

  def refresh_views
    ActiveRecord::Base.transaction do
      LatestBloodPressuresPerPatientPerMonth.refresh
      LatestBloodPressuresPerPatientPerQuarter.refresh
      PatientRegistrationsPerDayPerFacility.refresh
    end
  end

  context "index" do
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

  context "details" do
    render_views

    before do
      @facility_group = create(:facility_group, organization: organization)
      @facility = create(:facility, name: "CHC Barnagar", facility_group: @facility_group)
    end

    it "is successful for a facility" do
      patient = create(:patient, registration_facility: @facility, recorded_at: jan_2020.advance(months: -1))
      create(:blood_pressure, :under_control, recorded_at: jan_2020.advance(months: -1), patient: patient, facility: @facility)
      create(:blood_pressure, :hypertensive, recorded_at: jan_2020, facility: @facility)
      refresh_views

      Timecop.freeze("June 1 2020") do
        sign_in(cvho.email_authentication)
        get :details, params: {id: @facility.region.slug, report_scope: "facility"}
      end
      expect(response).to be_successful
    end

    it "is successful for a district" do
      patient = create(:patient, registration_facility: @facility, recorded_at: jan_2020.advance(months: -1))
      create(:blood_pressure, :under_control, recorded_at: jan_2020.advance(months: -1), patient: patient, facility: @facility)
      create(:blood_pressure, :hypertensive, recorded_at: jan_2020, facility: @facility)
      refresh_views

      Timecop.freeze("June 1 2020") do
        sign_in(cvho.email_authentication)
        get :details, params: {id: @facility.facility_group.region.slug, report_scope: "district"}
      end
      expect(response).to be_successful
    end

    it "is successful for a block" do
      patient_2 = create(:patient, registration_facility: @facility, recorded_at: "June 01 2019 00:00:00 UTC", registration_user: cvho)
      create(:blood_pressure, :hypertensive, recorded_at: "Feb 2020", facility: @facility, patient: patient_2, user: cvho)

      patient_1 = create(:patient, registration_facility: @facility, recorded_at: "September 01 2019 00:00:00 UTC", registration_user: cvho)
      create(:blood_pressure, :under_control, recorded_at: "December 10th 2019", patient: patient_1, facility: @facility, user: cvho)
      create(:blood_pressure, :hypertensive, recorded_at: jan_2020, facility: @facility, user: cvho)

      refresh_views

      block = @facility.region.block_region

      Timecop.freeze("June 1 2020") do
        sign_in(cvho.email_authentication)
        get :details, params: {id: block.slug, report_scope: "block"}
      end
      expect(response).to be_successful
    end
  end

  context "cohort" do
    render_views_on_ci

    before do
      @facility_group = create(:facility_group, organization: organization)
      @facility = create(:facility, name: "CHC Barnagar", facility_group: @facility_group)
    end

    it "retrieves monthly cohort data by default" do
      patient = create(:patient, registration_facility: @facility, registration_user: cvho, recorded_at: jan_2020.advance(months: -1))
      create(:blood_pressure, :under_control, recorded_at: jan_2020.advance(months: -1), patient: patient, facility: @facility)
      create(:blood_pressure, :hypertensive, recorded_at: jan_2020, facility: @facility)
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
      create(:blood_pressure, :under_control, recorded_at: jan_2020 + 1.day, patient: patient, facility: @facility)
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
  end

  context "show" do
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

    it "raises error if user does not have authorization to region" do
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

    it "renders successfully if report viewer has access to region" do
      other_fg = create(:facility_group, name: "other facility group", organization: organization)
      other_fg.facilities << build(:facility, name: "other facility")
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
        "name" => "Dec-2019",
        "bp_control_start_date" => "1-Oct-2019",
        "bp_control_end_date" => "31-Dec-2019",
        "start_date" => "1-Dec-2019",
        "ltfu_since_date" => "1-Dec-2018"
      }
      expect(data[:period_info][dec_2019_period]).to eq(period_hash)
    end

    it "returns period info for current month" do
      today = Date.current
      Timecop.freeze(today) do
        patient = create(:patient, registration_facility: @facility, recorded_at: today)
        create(:blood_pressure, :under_control, recorded_at: today, patient: patient, facility: @facility)
        refresh_views
        sign_in(cvho.email_authentication)
        get :show, params: {id: @facility.facility_group.slug, report_scope: "district"}
      end
      data = assigns(:data)
      expect(data[:period_info][Period.month(today.beginning_of_month)]).to_not be_nil
    end

    it "retrieves district data" do
      patient = create(:patient, registration_facility: @facility, recorded_at: jan_2020.advance(months: -4))
      create(:blood_pressure, :under_control, recorded_at: jan_2020.advance(months: -1), patient: patient, facility: @facility)
      create(:blood_pressure, :hypertensive, recorded_at: jan_2020, facility: @facility)
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
      create(:blood_pressure, :under_control, recorded_at: jan_2020.advance(months: -1), patient: patient, facility: @facility)
      create(:blood_pressure, :hypertensive, recorded_at: jan_2020, facility: @facility)
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

    it "retrieves facility district data" do
      patient = create(:patient, registration_facility: @facility, recorded_at: jan_2020.advance(months: -4))
      create(:blood_pressure, :under_control, recorded_at: jan_2020.advance(months: -1), patient: patient, facility: @facility)
      create(:blood_pressure, :hypertensive, recorded_at: jan_2020, facility: @facility)
      refresh_views

      Timecop.freeze("June 1 2020") do
        sign_in(cvho.email_authentication)
        get :show, params: {id: @facility.district, report_scope: "facility_district"}
      end
      expect(response).to be_successful
      data = assigns(:data)
      expect(data[:controlled_patients].size).to eq(10) # sanity check
      expect(data[:controlled_patients][dec_2019_period]).to eq(1)
    end

    it "retrieves block data" do
      patient_2 = create(:patient, registration_facility: @facility, recorded_at: "June 01 2019 00:00:00 UTC", registration_user: cvho)
      create(:blood_pressure, :hypertensive, recorded_at: "Feb 2020", facility: @facility, patient: patient_2, user: cvho)

      patient_1 = create(:patient, registration_facility: @facility, recorded_at: "September 01 2019 00:00:00 UTC", registration_user: cvho)
      create(:blood_pressure, :under_control, recorded_at: "December 10th 2019", patient: patient_1, facility: @facility, user: cvho)
      create(:blood_pressure, :hypertensive, recorded_at: jan_2020, facility: @facility, user: cvho)

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
      create(:blood_pressure, :under_control, recorded_at: jan_2020.advance(months: -1), patient: patient, facility: @facility)
      create(:blood_pressure, :hypertensive, recorded_at: jan_2020, facility: @facility)
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
      create(:blood_pressure, :under_control, recorded_at: jan_2020.advance(months: -1), patient: patient, facility: @facility)
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
      create(:blood_pressure, :under_control, recorded_at: jan_2020.advance(months: -1), patient: patient, facility: @facility)
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

  context "download" do
    render_views

    before do
      @facility_group = create(:facility_group, organization: organization)
      @facility = create(:facility, name: "CHC Barnagar", facility_group: @facility_group)
    end

    it "retrieves cohort data for a facility" do
      patient = create(:patient, registration_facility: @facility, recorded_at: jan_2020.advance(months: -1))
      create(:blood_pressure, :under_control, recorded_at: jan_2020.advance(months: -1), patient: patient, facility: @facility)
      create(:blood_pressure, :hypertensive, recorded_at: jan_2020, facility: @facility)
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
      create(:blood_pressure, :under_control, recorded_at: jan_2020.advance(months: -1), patient: patient, facility: @facility)
      create(:blood_pressure, :hypertensive, recorded_at: jan_2020, facility: @facility)
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

    it "retrieves cohort data for a facility district" do
      patient = create(:patient, registration_facility: @facility, recorded_at: jan_2020.advance(months: -1))
      create(:blood_pressure, :under_control, recorded_at: jan_2020.advance(months: -1), patient: patient, facility: @facility)
      create(:blood_pressure, :hypertensive, recorded_at: jan_2020, facility: @facility)
      refresh_views

      result = nil
      Timecop.freeze("June 1 2020") do
        sign_in(cvho.email_authentication)
        result = get :download, params: {id: @facility.district, report_scope: "facility_district", period: "quarter", format: "csv"}
      end

      expect(response).to be_successful
      expect(response.body).to include("#{@facility.district} Quarterly Cohort Report")
      expect(response.headers["Content-Disposition"]).to include('filename="facility_district-quarterly-cohort-report_')
      expect(result).to render_template("facility_group_cohort.csv.erb")
    end
  end

  describe "#whatsapp_graphics" do
    render_views

    before do
      @facility_group = create(:facility_group, organization: organization)
      @facility = create(:facility, name: "CHC Barnagar", facility_group: @facility_group)
      sign_in(cvho.email_authentication)
    end

    context "html requested" do
      it "renders graphics_header partial" do
        get :whatsapp_graphics, format: :html, params: {id: @facility.region.slug, report_scope: "facility"}

        expect(response).to be_ok
        expect(response).to render_template("shared/graphics/_graphics_partial")
      end
    end

    context "png requested" do
      it "renders the image template for downloading" do
        get :whatsapp_graphics, format: :png, params: {id: @facility_group.region.slug, report_scope: "district"}

        expect(response).to be_ok
        expect(response).to render_template("shared/graphics/image_template")
      end
    end
  end
end
