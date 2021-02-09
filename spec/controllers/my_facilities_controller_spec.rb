require "rails_helper"

RSpec::Matchers.define :facilities do |facilities|
  match { |actual| actual.map(&:id) == facilities.map(&:id) }
end

RSpec.describe MyFacilitiesController, type: :controller do
  let(:facility_group) { create(:facility_group) }
  let(:supervisor) { create(:admin, :manager, :with_access, resource: facility_group) }
  let(:facility) { create(:facility, facility_group: facility_group) }
  let(:december) { Period.month("December 2020") }

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
      facility
      get :index, params: {}

      expect(response).to be_successful
    end
  end

  describe "GET #bp_controlled" do
    it "returns a success response" do
      controlled = Timecop.freeze("August 15th 2020") {
        create_list(:patient, 2, full_name: "controlled", assigned_facility: facility, registration_user: supervisor)
      }
      Timecop.freeze("September 20th 2020") do
        controlled.each { |patient| create(:blood_pressure, :under_control, patient: patient, facility: facility, user: supervisor) }
      end
      Timecop.freeze("January 15th 2021") do
        refresh_views
        get :bp_controlled, params: {}
      end

      expect(response).to be_successful

      facility_data = assigns(:data_for_facility)[facility.name]

      expect(facility_data[:adjusted_registrations][december]).to eq(2)
      expect(facility_data[:controlled_patients_rate][Period.month("November 2020")]).to eq(100)
    end

    context "when admin has access to multiple facilities" do
      let(:other_district) { create(:facility_group, name: "other district") }
      let(:facility_2) { create(:facility, facility_group: other_district, zone: "foo") }
      let(:facility_3) { create(:facility, facility_group: other_district, zone: "oof") }

      before :each do
        supervisor.accesses.create! resource: other_district
        Timecop.freeze("August 15th 2020") do
          create_list(:patient, 2, full_name: "controlled in facility", assigned_facility: facility, registration_user: supervisor)
          create_list(:patient, 2, full_name: "controlled in facility_2", assigned_facility: facility_2, registration_user: supervisor)
          create_list(:patient, 1, full_name: "controlled in facility_3", assigned_facility: facility_3, registration_user: supervisor)
        end
        refresh_views
      end

      it "sets data_for_facility all facilities in the selected district" do
        Timecop.freeze("January 15th 2021") do
          get :bp_controlled, params: {facility_group: other_district.slug}
        end
        expect(response).to be_successful
        expect(assigns(:data_for_facility)[facility_2.name]).to_not be_nil
        expect(assigns(:data_for_facility)[facility_3.name]).to_not be_nil
        expect(assigns(:data_for_facility)[facility.name]).to be_nil
        expect(assigns(:display_sizes)).to eq(["small"])
      end

      it "sets data_for_facility for the selected facility zone but sets stats_by_size for all facilities in the group" do
        Timecop.freeze("January 15th 2021") do
          get :bp_controlled, params: {facility_group: other_district.slug, zone: facility_2.zone}
        end
        expect(response).to be_successful
        expect(assigns(:data_for_facility)[facility_2.name]).to_not be_nil
        expect(assigns(:data_for_facility)[facility_3.name]).to be_nil
        expect(assigns(:data_for_facility)[facility.name]).to be_nil
        expect(assigns(:display_sizes)).to eq(["small"])
        stats = assigns(:stats_by_size)
        patient_count = facility_2.assigned_patients.count + facility_3.assigned_patients.count
        expect(stats[:small][:periods][december][:cumulative_registrations]).to eq(patient_count)
      end
    end
  end

  describe "GET #bp_not_controlled" do
    it "returns a success response" do
      controlled = Timecop.freeze("August 15th 2020") {
        create_list(:patient, 2, full_name: "uncontrolled", assigned_facility: facility, registration_user: supervisor)
      }
      Timecop.freeze("September 20th 2020") do
        controlled.each { |patient| create(:blood_pressure, :hypertensive, patient: patient, facility: facility, user: supervisor) }
      end

      Timecop.freeze("January 15th 2021") do
        refresh_views
        get :bp_controlled, params: {}
      end

      expect(response).to be_successful
      facility_data = assigns(:data_for_facility)[facility.name]
      expect(facility_data[:adjusted_registrations][Period.month("December 2020")]).to eq(2)
      expect(facility_data[:uncontrolled_patients_rate][Period.month("November 2020")]).to eq(100)
      expect(assigns(:stats_by_size).keys).to eq(["small"])
      expect(assigns(:display_sizes)).to eq(["small"])
    end
  end

  describe "GET #missed_visits" do
    it "returns a success response" do
      controlled = Timecop.freeze("August 15th 2020") {
        create_list(:patient, 2, full_name: "controlled", assigned_facility: facility, registration_user: supervisor)
      }
      Timecop.freeze("September 20th 2020") do
        controlled.each { |patient| create(:blood_pressure, :under_control, patient: patient, facility: facility, user: supervisor) }
      end

      Timecop.freeze("January 15th 2021") do
        refresh_views
        get :bp_controlled, params: {}
      end

      expect(response).to be_successful
      facility_data = assigns(:data_for_facility)[facility.name]
      expect(facility_data[:adjusted_registrations][Period.month("December 2020")]).to eq(2)
      expect(facility_data[:missed_visits_rate][Period.month("December 2020")]).to eq(100)
      expect(assigns(:stats_by_size).keys).to eq(["small"])
      expect(assigns(:display_sizes)).to eq(["small"])
    end
  end
end
