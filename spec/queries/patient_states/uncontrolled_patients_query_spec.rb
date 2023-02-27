require "rails_helper"

describe PatientStates::UncontrolledPatientsQuery do
  around do |example|
    with_reporting_time_zone { example.run }
  end

  let(:regions) { setup_district_with_facilities }
  let(:period) { Period.current }

  describe "#call" do
    it "returns all the uncontrolled patients in a region as of the given period" do
      facility_1_controlled_patients = create_list(:patient, 1, :controlled, assigned_facility: regions[:facility_1])
      facility_1_uncontrolled_patients = create_list(:patient, 1, :uncontrolled, assigned_facility: regions[:facility_1])
      facility_2_controlled_patients = create_list(:patient, 1, :controlled, assigned_facility: regions[:facility_2])
      facility_2_uncontrolled_patients = create_list(:patient, 1, :uncontrolled, assigned_facility: regions[:facility_2])
      refresh_views

      expect(PatientStates::UncontrolledPatientsQuery.new(regions[:facility_1].region, period)
                                                   .call
                                                   .map(&:patient_id))
        .to match_array(facility_1_uncontrolled_patients.map(&:id))

      expect(PatientStates::UncontrolledPatientsQuery.new(regions[:facility_2].region, period)
                                                   .call
                                                   .map(&:patient_id))
        .to match_array(facility_2_uncontrolled_patients.map(&:id))

      expect(PatientStates::UncontrolledPatientsQuery.new(regions[:facility_1].region, period)
                                                   .call
                                                   .map(&:patient_id))
        .not_to include(*facility_1_controlled_patients.map(&:id))

      expect(PatientStates::UncontrolledPatientsQuery.new(regions[:facility_2].region, period)
                                                   .call
                                                   .map(&:patient_id))
        .not_to include(*facility_2_controlled_patients.map(&:id))

      expect(PatientStates::UncontrolledPatientsQuery.new(regions[:region].region, period)
                                                   .call
                                                   .map(&:patient_id))
        .to match_array((facility_1_uncontrolled_patients + facility_2_uncontrolled_patients).map(&:id))
    end

    it "returns same number of uncontrolled patients as in the reporting facility states" do
      _facility_1_uncontrolled_patients = create_list(:patient, 1, :controlled, assigned_facility: regions[:facility_1])
      refresh_views

      expect(PatientStates::UncontrolledPatientsQuery.new(regions[:facility_1].region, period).call.count)
        .to eq(Reports::FacilityState
                 .find_by(facility_id: regions[:facility_1].id, month_date: period.begin)
                 .adjusted_uncontrolled_under_care)
    end
  end
end

