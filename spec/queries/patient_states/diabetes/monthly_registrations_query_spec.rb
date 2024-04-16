require "rails_helper"

describe PatientStates::Diabetes::MonthlyRegistrationsQuery do
  around do |example|
    with_reporting_time_zone { example.run }
  end

  let(:regions) { setup_district_with_facilities }
  let(:period) { Period.current }

  context "monthly registrations" do
    it "returns the registrations in a facility for that month" do
      facility_1_new_registrations = create_list(:patient, 2, :diabetes, assigned_facility: regions[:facility_1])
      facility_2_new_registrations = create_list(:patient, 2, :diabetes, assigned_facility: regions[:facility_2])
      refresh_views

      expect(PatientStates::Diabetes::CumulativeAssignedPatientsQuery.new(regions[:facility_1].region, period)
                                                           .call.map(&:patient_id))
        .to match_array(facility_1_new_registrations.map(&:id))

      expect(PatientStates::Diabetes::CumulativeAssignedPatientsQuery.new(regions[:facility_2].region, period)
                                                           .call.map(&:patient_id))
        .to match_array(facility_2_new_registrations.map(&:id))

      expect(PatientStates::Diabetes::CumulativeAssignedPatientsQuery.new(regions[:region].region, period)
                                                           .call.map(&:patient_id))
        .to match_array((facility_1_new_registrations + facility_2_new_registrations).map(&:id))
    end

    it "returns the same number of monthly registrations as in reporting facility states" do
      refresh_views

      _facility_1_new_registrations = create_list(:patient, 2, :diabetes, registration_facility: regions[:facility_1])
      _facility_2_new_registrations = create_list(:patient, 3, :diabetes, registration_facility: regions[:facility_2])

      refresh_views

      expect(PatientStates::Diabetes::MonthlyRegistrationsQuery.new(regions[:facility_1].region, period).call.count)
        .to eq(Reports::FacilityState
                 .find_by(facility_id: regions[:facility_1].id, month_date: period.begin)
                 .monthly_diabetes_registrations)

      expect(PatientStates::Diabetes::MonthlyRegistrationsQuery.new(regions[:facility_2].region, period).call.count)
        .to eq(Reports::FacilityState
                 .find_by(facility_id: regions[:facility_2].id, month_date: period.begin)
                 .monthly_diabetes_registrations)
    end
  end
end
