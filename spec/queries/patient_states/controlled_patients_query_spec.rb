require "rails_helper"

describe PatientStates::ControlledPatientsQuery do
  around do |example|
    with_reporting_time_zone { example.run }
  end

  let(:regions) { setup_district_with_facilities }
  let(:period) { Period.current }

  describe "#call" do
    it "returns all the controlled patients in a region as of the given period" do
      facility_1_controlled_patients = create_list(:patient, 1, :controlled, assigned_facility: regions[:facility_1])
      facility_1_uncontrolled_patients = create_list(:patient, 1, :uncontrolled, assigned_facility: regions[:facility_1])
      facility_2_controlled_patients = create_list(:patient, 1, :controlled, assigned_facility: regions[:facility_2])
      facility_2_uncontrolled_patients = create_list(:patient, 1, :uncontrolled, assigned_facility: regions[:facility_2])
      refresh_views

      expect(PatientStates::ControlledPatientsQuery.new(regions[:facility_1].region, period)
                                                   .call
                                                   .map(&:patient_id))
        .to match_array(facility_1_controlled_patients.map(&:id))

      expect(PatientStates::ControlledPatientsQuery.new(regions[:facility_2].region, period)
                                                   .call
                                                   .map(&:patient_id))
        .to match_array(facility_2_controlled_patients.map(&:id))

      expect(PatientStates::ControlledPatientsQuery.new(regions[:facility_1].region, period)
                                                   .call
                                                   .map(&:patient_id))
        .not_to include(*facility_1_uncontrolled_patients.map(&:id))

      expect(PatientStates::ControlledPatientsQuery.new(regions[:facility_2].region, period)
                                                   .call
                                                   .map(&:patient_id))
        .not_to include(*facility_2_uncontrolled_patients.map(&:id))

      expect(PatientStates::ControlledPatientsQuery.new(regions[:region].region, period)
                                                   .call
                                                   .map(&:patient_id))
        .to match_array((facility_1_controlled_patients + facility_2_controlled_patients).map(&:id))
    end

    it "returns same number of controlled patients as in the reporting facility states" do
      facility_1_controlled_patients = create_list(:patient, 1, :controlled, assigned_facility: regions[:facility_1])
      refresh_views

      expect(PatientStates::ControlledPatientsQuery.new(regions[:facility_1].region, period).call.count)
        .to eq(Reports::FacilityState
                 .find_by(facility_id: regions[:facility_1].id, month_date: period.begin)
                 .adjusted_controlled_under_care)
    end
  end
end
