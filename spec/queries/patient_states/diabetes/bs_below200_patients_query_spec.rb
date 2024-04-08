require "rails_helper"

describe PatientStates::Diabetes::BsBelow200PatientsQuery do
  around do |example|
    with_reporting_time_zone { example.run }
  end

  let(:regions) { setup_district_with_facilities }
  let(:period) { Period.current }

  describe "#call" do
    it "returns all the patients with a blood sugar measurement below 200 in a region as of the given period" do
      facility_1_bs_below_200_patients = create_list(:patient, 1, :bs_below_200, assigned_facility: regions[:facility_1])
      facility_1_bs_200_to_300_patients = create_list(:patient, 1, :bs_200_to_300, assigned_facility: regions[:facility_1])
      facility_1_bs_over_300_patients = create_list(:patient, 1, :bs_over_300, assigned_facility: regions[:facility_1])
      facility_2_bs_below_200_patients = create_list(:patient, 1, :bs_below_200, assigned_facility: regions[:facility_2])
      facility_2_bs_200_to_300_patients = create_list(:patient, 1, :bs_200_to_300, assigned_facility: regions[:facility_2])
      facility_2_bs_over_300_patients = create_list(:patient, 1, :bs_over_300, assigned_facility: regions[:facility_2])
      refresh_views

      expect(PatientStates::Diabetes::BsBelow200PatientsQuery.new(regions[:facility_1].region, period)
                                                   .call
                                                   .map(&:patient_id))
        .to match_array(facility_1_bs_below_200_patients.map(&:id))

      expect(PatientStates::Diabetes::BsBelow200PatientsQuery.new(regions[:facility_2].region, period)
                                                   .call
                                                   .map(&:patient_id))
        .to match_array(facility_2_bs_below_200_patients.map(&:id))

      expect(PatientStates::Diabetes::BsBelow200PatientsQuery.new(regions[:facility_1].region, period)
                                                   .call
                                                   .map(&:patient_id))
        .not_to include(*(facility_1_bs_200_to_300_patients.map(&:id) + facility_1_bs_over_300_patients.map(&:id)))

      expect(PatientStates::Diabetes::BsBelow200PatientsQuery.new(regions[:facility_2].region, period)
                                                   .call
                                                   .map(&:patient_id))
        .not_to include(*(facility_2_bs_200_to_300_patients.map(&:id) + facility_2_bs_over_300_patients.map(&:id)))

      expect(PatientStates::Diabetes::BsBelow200PatientsQuery.new(regions[:region].region, period)
                                                   .call
                                                   .map(&:patient_id))
        .to match_array((facility_1_bs_below_200_patients + facility_2_bs_below_200_patients).map(&:id))
    end

    it "returns same number of patients with a blood sugar measurement below 200 as in the reporting facility states" do
      _facility_1_bs_below_200_patients = create_list(:patient, 1, :bs_below_200, assigned_facility: regions[:facility_1])
      refresh_views

      expect(PatientStates::Diabetes::BsBelow200PatientsQuery.new(regions[:facility_1].region, period).call.count)
        .to eq(Reports::FacilityState
                 .find_by(facility_id: regions[:facility_1].id, month_date: period.begin)
                 .adjusted_bs_below_200_under_care)
    end
  end
end
