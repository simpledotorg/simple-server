require "rails_helper"

RSpec::Matchers.define :facilities do |facilities|
  match { |actual| actual.map(&:id) == facilities.map(&:id) }
end

RSpec.describe MyFacilitiesController, type: :controller do
  let(:facility_group) { create(:facility_group) }
  let(:supervisor) { create(:admin, :manager, :with_access, resource: facility_group) }

  render_views

  before do
    sign_in(supervisor.email_authentication)
  end

  def refresh_views
    ActiveRecord::Base.transaction do
      LatestBloodPressuresPerPatientPerMonth.refresh
      LatestBloodPressuresPerPatientPerQuarter.refresh
      PatientRegistrationsPerDayPerFacility.refresh
    end
  end

  describe "GET #index" do
    it "returns a success response" do
      create(:facility, facility_group: facility_group)

      get :index, params: {}

      expect(response).to be_successful
    end
  end

  describe "GET #bp_controlled" do
    it "returns a success response" do
      facility = create(:facility, facility_group: facility_group)

      controlled = Timecop.freeze("August 15th 2020") {
        create_list(:patient, 2, full_name: "controlled", assigned_facility: facility, registration_user: supervisor)
      }

      Timecop.freeze("September 20th 2020") do
        controlled.each { |patient| create(:blood_pressure, :under_control, patient: patient, facility: facility) }
      end

      refresh_views

      Timecop.freeze("January 15th 2021") do
        get :bp_controlled, params: {}
      end

      expect(response).to be_successful

      facility_data = assigns(:data_for_facility)[facility.name]

      expect(facility_data[:adjusted_registrations][Period.month("December 2020")]).to eq(2)
      expect(facility_data[:controlled_patients_rate][Period.month("November 2020")]).to eq(100)
    end

    it "only returns data for the selected district" do
      other_district = create(:facility_group, name: "other district")
      facility_1 = create(:facility, facility_group: other_district)
      supervisor.accesses.create! resource: other_district
      facility_2 = create(:facility, facility_group: facility_group)

      Timecop.freeze("August 15th 2020") {
        create_list(:patient, 2, full_name: "controlled in facility_1", assigned_facility: facility_1, registration_user: supervisor)
        create_list(:patient, 2, full_name: "controlled in facility_2", assigned_facility: facility_2, registration_user: supervisor)
      }

      refresh_views

      Timecop.freeze("January 15th 2021") do
        get :bp_controlled, params: {facility_group: other_district.slug}
      end

      expect(response).to be_successful

      expect(assigns(:data_for_facility)[facility_1.name]).to_not be_nil
      expect(assigns(:data_for_facility)[facility_2.name]).to be_nil
    end
  end

  describe "GET #bp_not_controlled" do
    it "returns a success response" do
      facility = create(:facility, facility_group: facility_group)
      controlled = Timecop.freeze("August 15th 2020") {
        create_list(:patient, 2, full_name: "uncontrolled", assigned_facility: facility, registration_user: supervisor)
      }

      Timecop.freeze("September 20th 2020") do
        controlled.each { |patient| create(:blood_pressure, patient: patient, facility: facility) }
      end

      refresh_views

      Timecop.freeze("January 15th 2021") do
        get :bp_controlled, params: {}
      end

      expect(response).to be_successful

      facility_data = assigns(:data_for_facility)[facility.name]

      expect(facility_data[:adjusted_registrations][Period.month("December 2020")]).to eq(2)
      expect(facility_data[:uncontrolled_patients_rate][Period.month("November 2020")]).to eq(100)
    end
  end

  describe "GET #missed_visits" do
    it "returns a success response" do
      facility = create(:facility, facility_group: facility_group)

      controlled = Timecop.freeze("August 15th 2020") {
        create_list(:patient, 2, full_name: "controlled", assigned_facility: facility, registration_user: supervisor)
      }

      Timecop.freeze("September 20th 2020") do
        controlled.each { |patient| create(:blood_pressure, :under_control, patient: patient, facility: facility) }
      end

      refresh_views

      Timecop.freeze("January 15th 2021") do
        get :bp_controlled, params: {}
      end

      expect(response).to be_successful

      facility_data = assigns(:data_for_facility)[facility.name]

      expect(facility_data[:adjusted_registrations][Period.month("December 2020")]).to eq(2)
      expect(facility_data[:missed_visits_rate][Period.month("December 2020")]).to eq(100)
    end
  end
end
