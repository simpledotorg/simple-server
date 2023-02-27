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
      _facility_1_patients = create_list(:patient, 2, assigned_facility: regions[:facility_1])
      _facility_2_patients = create_list(:patient, 3, assigned_facility: regions[:facility_2])

      refresh_views

      expect(PatientStates::CumulativeAssignedPatientsQuery.new(regions[:facility_1].region, period).call.count)
        .to eq(Reports::FacilityState
                 .find_by(facility_id: regions[:facility_1].id, month_date: period.begin)
                 .cumulative_assigned_patients)

      expect(PatientStates::CumulativeAssignedPatientsQuery.new(regions[:facility_2].region, period).call.count)
        .to eq(Reports::FacilityState
                 .find_by(facility_id: regions[:facility_2].id, month_date: period.begin)
                 .cumulative_assigned_patients)
    end

    it "does not include dead patients" do
      facility_1_patients = create_list(:patient, 2, assigned_facility: regions[:facility_1])
      facility_1_dead_patient = create(:patient, assigned_facility: regions[:facility_1], status: 'dead')
      refresh_views

      cumulative_assigned_patient_ids = PatientStates::CumulativeAssignedPatientsQuery
                                          .new(regions[:facility_1].region, period)
                                          .call
                                          .map(&:patient_id)
      expect(cumulative_assigned_patient_ids).to match_array(facility_1_patients.map(&:id))
      expect(cumulative_assigned_patient_ids).not_to include(facility_1_dead_patient[:id])
    end
  end
end
