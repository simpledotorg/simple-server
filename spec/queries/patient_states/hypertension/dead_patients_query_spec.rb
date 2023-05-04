require "rails_helper"

describe PatientStates::Hypertension::DeadPatientsQuery do
  around do |example|
    with_reporting_time_zone { example.run }
  end

  let(:regions) { setup_district_with_facilities }
  let(:period) { Period.current }

  context "dead patients" do
    it "returns only dead patients in a facility as of the given period" do
      facility_1_living_patients = create_list(:patient, 2, assigned_facility: regions[:facility_1])
      facility_1_dead_patients = create(:patient, :dead, assigned_facility: regions[:facility_1])
      facility_2_living_patients = create_list(:patient, 2, assigned_facility: regions[:facility_2])

      refresh_views

      expect(PatientStates::Hypertension::DeadPatientsQuery.new(regions[:facility_1].region, period)
                                             .call.map(&:patient_id))
        .to match_array(facility_1_dead_patients[:id])

      expect(PatientStates::Hypertension::DeadPatientsQuery.new(regions[:facility_1].region, period)
                                             .call.map(&:patient_id))
        .not_to include(*facility_1_living_patients.map(&:id))

      expect(PatientStates::Hypertension::DeadPatientsQuery.new(regions[:facility_2].region, period)
                                             .call.map(&:patient_id).count)
        .to eq(0)

      expect(PatientStates::Hypertension::DeadPatientsQuery.new(regions[:facility_2].region, period)
                                             .call.map(&:patient_id))
        .not_to include(*facility_2_living_patients.map(&:id))
    end

    it "returns the same number of dead patients as in reporting facility states" do
      _facility_1_living_patients = create_list(:patient, 2, assigned_facility: regions[:facility_1])
      _facility_1_dead_patients = create(:patient, :dead, assigned_facility: regions[:facility_1])
      _facility_2_living_patients = create_list(:patient, 2, assigned_facility: regions[:facility_2])

      refresh_views

      expect(PatientStates::Hypertension::DeadPatientsQuery.new(regions[:facility_1].region, period).call.count)
        .to eq(Reports::FacilityState
                 .find_by(facility_id: regions[:facility_1].id, month_date: period.begin)
                 .dead)

      expect(PatientStates::Hypertension::DeadPatientsQuery.new(regions[:facility_2].region, period).call.count)
        .to eq(Reports::FacilityState
                 .find_by(facility_id: regions[:facility_2].id, month_date: period.begin)
                 .dead)
    end
  end
end
