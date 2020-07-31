require "rails_helper"

RSpec.describe Reports::RegionsController, type: :controller do
  let(:dec_2019_period) { Period.month(Date.parse("December 2019")) }
  let(:organization) { FactoryBot.create(:organization) }
  let(:cvho) do
    create(:admin, :supervisor, organization: organization).tap do |user|
      user.user_permissions << build(:user_permission, permission_slug: :view_cohort_reports, resource: organization)
    end
  end

  context "index" do
    it "loads available districts" do
      sign_in(cvho.email_authentication)
      get :index
      expect(response).to be_successful
    end
  end

  context "details" do
    render_views

    before do
      @facility_group = create(:facility_group, organization: organization)
      @facility = create(:facility, name: "CHC Barnagar", facility_group: @facility_group)
    end

    it "is successful" do
      jan_2020 = Time.parse("January 1 2020")
      patient = create(:patient, registration_facility: @facility, recorded_at: jan_2020.advance(months: -1))
      create(:blood_pressure, :under_control, recorded_at: jan_2020.advance(months: -1), patient: patient, facility: @facility)
      create(:blood_pressure, :hypertensive, recorded_at: jan_2020, facility: @facility)
      LatestBloodPressuresPerPatient.refresh
      LatestBloodPressuresPerPatientPerMonth.refresh

      Timecop.freeze("June 1 2020") do
        sign_in(cvho.email_authentication)
        get :details, params: {id: @facility.facility_group.region_slug}
      end
      expect(response).to be_successful
    end
  end

  context "cohort" do
    render_views

    before do
      @facility_group = create(:facility_group, organization: organization)
      @facility = create(:facility, name: "CHC Barnagar", facility_group: @facility_group)
    end

    it "is successful" do
      jan_2020 = Time.parse("January 1 2020")
      patient = create(:patient, registration_facility: @facility, recorded_at: jan_2020.advance(months: -1))
      create(:blood_pressure, :under_control, recorded_at: jan_2020.advance(months: -1), patient: patient, facility: @facility)
      create(:blood_pressure, :hypertensive, recorded_at: jan_2020, facility: @facility)
      LatestBloodPressuresPerPatient.refresh
      LatestBloodPressuresPerPatientPerMonth.refresh

      Timecop.freeze("June 1 2020") do
        sign_in(cvho.email_authentication)
        get :cohort, params: {id: @facility.facility_group.region_slug}
      end
      expect(response).to be_successful
    end
  end

  context "show" do
    render_views

    before do
      @facility_group = create(:facility_group, organization: organization)
      @facility = create(:facility, name: "CHC Barnagar", facility_group: @facility_group)
    end

    it "raises error if matching region slug found" do
      expect {
        sign_in(cvho.email_authentication)
        get :show, params: {id: "String-unknown", report_scope: "bad-report_scope"}
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "retrieves district data" do
      jan_2020 = Time.parse("January 1 2020")
      patient = create(:patient, registration_facility: @facility, recorded_at: jan_2020.advance(months: -1))
      create(:blood_pressure, :under_control, recorded_at: jan_2020.advance(months: -1), patient: patient, facility: @facility)
      create(:blood_pressure, :hypertensive, recorded_at: jan_2020, facility: @facility)
      LatestBloodPressuresPerPatient.refresh
      LatestBloodPressuresPerPatientPerMonth.refresh

      Timecop.freeze("June 1 2020") do
        sign_in(cvho.email_authentication)
        get :show, params: {id: @facility.facility_group.region_slug}
      end
      expect(response).to be_successful
      data = assigns(:data)
      expect(data[:controlled_patients].size).to eq(6) # retrieves data back to first registration
      expect(data[:controlled_patients][dec_2019_period]).to eq(1)
    end

    it "can retrieve quarterly data" do
      jan_2020 = Time.parse("January 1 2020")
      patient = create(:patient, registration_facility: @facility, recorded_at: jan_2020.advance(months: -1))
      create(:blood_pressure, :under_control, recorded_at: jan_2020.advance(months: -1), patient: patient, facility: @facility)
      create(:blood_pressure, :hypertensive, recorded_at: jan_2020, facility: @facility)
      LatestBloodPressuresPerPatient.refresh
      LatestBloodPressuresPerPatientPerMonth.refresh

      Timecop.freeze("December 1 2019") do
        sign_in(cvho.email_authentication)
        get :show, params: {id: @facility.facility_group.region_slug, period: {type: "quarter", value: "Q4 2019"}}
        data = assigns(:data)
        expect(data[:controlled_patients].size).to eq(6) # retrieves data back to first registration
        expect(data[:controlled_patients]["Q4 2019"]).to eq(1)
      end
    end

    it "retrieves facility data" do
      jan_2020 = Time.parse("January 1 2020")
      patient = create(:patient, registration_facility: @facility, recorded_at: jan_2020.advance(months: -1))
      create(:blood_pressure, :under_control, recorded_at: jan_2020.advance(months: -1), patient: patient, facility: @facility)
      create(:blood_pressure, :hypertensive, recorded_at: jan_2020, facility: @facility)
      LatestBloodPressuresPerPatient.refresh
      LatestBloodPressuresPerPatientPerMonth.refresh

      Timecop.freeze("June 1 2020") do
        sign_in(cvho.email_authentication)
        get :show, params: {id: @facility.region_slug}
      end
      expect(response).to be_successful
      data = assigns(:data)
      expect(data[:controlled_patients].size).to eq(6) # retrieves data back to first registration
      expect(data[:controlled_patients]["Dec 2019"]).to eq(1)
    end
  end
end
