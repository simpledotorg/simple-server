require "rails_helper"

describe PatientStates::CumulativeAssignedPatientsQuery do
  around do |example|
    with_reporting_time_zone { example.run }
  end

  let(:regions) { setup_district_with_facilities }
  let(:period) { Period.current }

  context "cumulative assigned patients" do
    it "returns all the assigned patients in a facility as of the given period" do
      facility_1_patients = create_list(:patient, 2, assigned_facility: regions[:facility_1])
      facility_2_patients = create_list(:patient, 2, assigned_facility: regions[:facility_2])
      refresh_views

      expect(PatientStates::CumulativeAssignedPatientsQuery.new(regions[:facility_1].region, period)
               .call.map(&:patient_id))
        .to match_array(facility_1_patients.map(&:id))

      expect(PatientStates::CumulativeAssignedPatientsQuery.new(regions[:facility_2].region, period)
                               .call.map(&:patient_id))
        .to match_array(facility_2_patients.map(&:id))

      expect(PatientStates::CumulativeAssignedPatientsQuery.new(regions[:region].region, period)
                               .call.map(&:patient_id))
        .to match_array((facility_1_patients + facility_2_patients).map(&:id))
    end

    it "returns the same number of cumulative patients as in reporting facility states" do
      facility_1_patients = create_list(:patient, 2, assigned_facility: regions[:facility_1])
      facility_2_patients = create_list(:patient, 3, assigned_facility: regions[:facility_2])

      refresh_views

      expect(PatientStates::CumulativeAssignedPatientsQuery.new(regions[:facility_1].region, period)
               .call.count)
        .to eq(Reports::FacilityState
                 .find_by(facility_id: regions[:facility_1].id, month_date: period.begin)
                 .cumulative_assigned_patients)

      expect(PatientStates::CumulativeAssignedPatientsQuery.new(regions[:facility_2].region, period)
                               .call.count)
        .to eq(Reports::FacilityState
                 .find_by(facility_id: regions[:facility_2].id, month_date: period.begin)
                 .cumulative_assigned_patients)
    end
  end
end
