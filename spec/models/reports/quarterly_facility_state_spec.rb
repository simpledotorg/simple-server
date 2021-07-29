require "rails_helper"

RSpec.describe Reports::QuarterlyFacilityState, {type: :model, reporting_spec: true} do
  describe "Associations" do
    it { should belong_to(:facility) }
  end

  around do |example|
    freeze_time_for_reporting_specs(example)
  end

  context "quarterly cohort outcomes" do
    it "computes totals correctly" do
      facility = create(:facility)
      two_quarters_ago = june_2021[:now] - 6.months
      previous_quarter = june_2021[:now] - 3.months
      this_quarter = june_2021[:now]

      patients_controlled = create_list(:patient, 2, assigned_facility: facility, recorded_at: previous_quarter)
      patients_controlled.each do |patient|
        create(:bp_with_encounter, :under_control, patient: patient, recorded_at: this_quarter)
      end

      patients_uncontrolled = create_list(:patient, 3, assigned_facility: facility, recorded_at: previous_quarter)
      patients_uncontrolled.each do |patient|
        create(:bp_with_encounter, :hypertensive, patient: patient, recorded_at: this_quarter)
      end

      patients_missed_visit = create_list(:patient, 4, assigned_facility: facility, recorded_at: previous_quarter)
      patients_missed_visit.each do |patient|
        create(:bp_with_encounter, patient: patient, recorded_at: previous_quarter)
      end

      _patient_no_visit = create(:patient, assigned_facility: facility, recorded_at: previous_quarter)
      _patient_not_in_cohort = create(:patient, assigned_facility: facility, recorded_at: two_quarters_ago)

      patients_visited_no_bp = create_list(:patient, 2, assigned_facility: facility, recorded_at: previous_quarter)
      patients_visited_no_bp.each do |patient|
        create(:prescription_drug,
          device_created_at: this_quarter,
          facility: facility,
          patient: patient,
          user: patient.registration_user)
        create(:blood_pressure, patient: patient, recorded_at: previous_quarter)
      end

      RefreshMaterializedViews.new.refresh_v2
      with_reporting_time_zone do
        quarterly_facility_state_2021_Q2 = described_class.find_by(facility: facility, quarter_string: "2021-2")

        pp Reports::PatientState.where(assigned_facility_id: facility.id, month_string: "2021-06", quarters_since_registration: 1).pluck(:quarters_since_bp)
        pp Reports::PatientState.where(assigned_facility_id: facility.id, month_string: "2021-06", quarters_since_registration: 1).pluck(:quarters_since_visit)
        pp Reports::PatientState.where(assigned_facility_id: facility.id, month_string: "2021-06", quarters_since_registration: 1).pluck(:htn_treatment_outcome_in_quarter)
        pp Reports::PatientState.where(assigned_facility_id: facility.id, month_string: "2021-06", quarters_since_registration: 1, htn_treatment_outcome_in_quarter: "missed_visit").count
        pp quarterly_facility_state_2021_Q2
        expect(quarterly_facility_state_2021_Q2.quarterly_cohort_controlled).to eq 2
        expect(quarterly_facility_state_2021_Q2.quarterly_cohort_patients).to eq 12
        expect(quarterly_facility_state_2021_Q2.quarterly_cohort_visited_no_bp).to eq 2
        expect(quarterly_facility_state_2021_Q2.quarterly_cohort_uncontrolled).to eq 3
        expect(quarterly_facility_state_2021_Q2.quarterly_cohort_missed_visit).to eq 5
      end
    end
  end
end
