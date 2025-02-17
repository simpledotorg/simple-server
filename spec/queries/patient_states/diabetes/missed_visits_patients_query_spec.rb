require "rails_helper"

describe PatientStates::Diabetes::MissedVisitsPatientsQuery do
  around do |example|
    with_reporting_time_zone { example.run }
  end

  let(:regions) { setup_district_with_facilities }
  let(:period) { Period.current }

  context "missed visits" do
    it "returns patients under care with missed visits in a facility as of the given period" do
      facility_1_under_care_patients = create_list(:patient, 2, :diabetes, assigned_facility: regions[:facility_1])
      facility_1_missed_visit_patients = create(:patient, :diabetes, :missed_visit_under_care, assigned_facility: regions[:facility_1])
      facility_2_under_care_patients = create_list(:patient, 2, :diabetes, assigned_facility: regions[:facility_2])

      refresh_views

      expect(PatientStates::Diabetes::MissedVisitsPatientsQuery.new(regions[:facility_1].region, period)
                                                       .call.map(&:patient_id))
        .to match_array(facility_1_missed_visit_patients[:id])

      expect(PatientStates::Diabetes::MissedVisitsPatientsQuery.new(regions[:facility_1].region, period)
                                                       .call.map(&:patient_id))
        .not_to include(*facility_1_under_care_patients.map(&:id))

      expect(PatientStates::Diabetes::MissedVisitsPatientsQuery.new(regions[:facility_2].region, period)
                                                       .call.map(&:patient_id).count)
        .to eq(0)

      expect(PatientStates::Diabetes::MissedVisitsPatientsQuery.new(regions[:facility_2].region, period)
                                                       .call.map(&:patient_id))
        .not_to include(*facility_2_under_care_patients.map(&:id))
    end

    it "returns the same number of under care patients with missed visits as in reporting facility states" do
      _facility_1_missed_visit_patients = create(:patient, :diabetes, :missed_visit_under_care, assigned_facility: regions[:facility_1])
      _facility_2_under_care_patients = create_list(:patient, 2, :diabetes, :under_care, assigned_facility: regions[:facility_2])

      refresh_views

      expect(PatientStates::Diabetes::MissedVisitsPatientsQuery.new(regions[:facility_1].region, period).call.count)
        .to eq(Reports::FacilityState
                 .find_by(facility_id: regions[:facility_1].id, month_date: period.begin)
                 .adjusted_bs_missed_visit_under_care)

      expect(PatientStates::Diabetes::MissedVisitsPatientsQuery.new(regions[:facility_2].region, period).call.count)
        .to eq(Reports::FacilityState
                 .find_by(facility_id: regions[:facility_2].id, month_date: period.begin)
                 .adjusted_bs_missed_visit_under_care)
    end
  end
end
