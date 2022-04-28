require "rails_helper"

RSpec.describe OverviewQuery do
  around do |example|
    with_reporting_time_zone { example.run }
  end

  describe "#inactive_facilities" do
    let!(:active_facility) { create(:facility) }
    let!(:inactive_facility) { create :facility }
    let!(:inactive_facility_with_zero_bps) { create :facility }
    let!(:inactive_facility_with_bp_outside_period) { create :facility }

    let!(:user) { create(:user, registration_facility: active_facility) }
    let!(:non_htn_patient) { create(:patient, registration_user: user, registration_facility: user.facility) }

    threshold_days = 30
    threshold_bps = 1
    date = threshold_days.days.ago.beginning_of_day + 1.day

    let!(:blood_pressures_for_active_facility) do
      create_list(:blood_pressure, threshold_bps, facility: active_facility, recorded_at: date)
      create(:blood_pressure, patient: non_htn_patient, facility: active_facility, recorded_at: date)
    end

    let!(:blood_pressures_for_inactive_facility) do
      create_list(:blood_pressure, threshold_bps - 1, facility: inactive_facility, recorded_at: date)
    end

    let!(:blood_pressures_for_inactive_facility_with_bp_outside_period) do
      create_list(:blood_pressure,
        threshold_bps,
        user: user,
        facility: inactive_facility_with_bp_outside_period,
        recorded_at: date - 1.month)
    end

    before do
      BloodPressuresPerFacilityPerDay.refresh
    end

    it "returns only inactive facilities" do
      facility_ids = [active_facility.id, inactive_facility.id, inactive_facility_with_zero_bps.id, inactive_facility_with_bp_outside_period.id]

      expect(described_class.new(facilities: Facility.where(id: facility_ids)).inactive_facilities.map(&:id))
        .to match_array([inactive_facility.id, inactive_facility_with_zero_bps.id, inactive_facility_with_bp_outside_period.id])
    end
  end

  describe "#total_bps_in_last_n_days" do
    let!(:facility) { create(:facility) }
    let!(:user) { create(:user, registration_facility: facility) }

    let!(:htn_patient) { create(:patient, registration_user: user, registration_facility: facility) }
    let!(:non_htn_patient) { create(:patient, :without_hypertension, registration_user: user, registration_facility: facility) }

    let!(:bp_for_htn_patient) do
      create(:blood_pressure, user: user, facility: facility, patient: htn_patient, recorded_at: 1.day.ago)
    end
    let!(:bp_for_non_htn_patient) do
      create(:blood_pressure, user: user, facility: facility, patient: non_htn_patient, recorded_at: 1.day.ago)
    end

    before do
      BloodPressuresPerFacilityPerDay.refresh
    end

    context "considers only htn diagnosed patients" do
      specify { expect(described_class.new(facilities: facility).total_bps_in_last_n_days(n: 2)[facility.id]).to eq(1) }
    end
  end
end
