# frozen_string_literal: true

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
    let!(:patient) { create(:patient, registration_user: user, registration_facility: user.facility) }
    let!(:patient_2) { create(:patient, registration_user: user, registration_facility: user.facility) }
    let!(:non_htn_patient) { create(:patient, registration_user: user, registration_facility: user.facility) }

    date_range = (1..described_class::INACTIVITY_THRESHOLD_DAYS).map { |n| n.days.ago.beginning_of_day }

    let!(:blood_pressures_for_active_facility) do
      date_range.map { |date|
        [create(:blood_pressure, :with_encounter, facility: active_facility, patient: patient, user: user, recorded_at: date),
          create(:blood_pressure, :with_encounter, facility: active_facility, patient: patient_2, user: user, recorded_at: date)]
      }.flatten
    end

    let!(:blood_pressures_for_inactive_facility) do
      date_range.map { |date|
        [create(:blood_pressure, :with_encounter, facility: inactive_facility, patient: patient, user: user, recorded_at: date),
          create(:blood_pressure, :with_encounter, patient: non_htn_patient, user: user, facility: inactive_facility_with_bp_outside_period, recorded_at: date)]
      }.flatten
    end

    let!(:blood_pressures_for_inactive_facility_with_bp_outside_period) do
      date_range.map { |date|
        [create(:blood_pressure,
          :with_encounter,
          patient: patient,
          user: user,
          facility: inactive_facility_with_bp_outside_period,
          recorded_at: date - 1.month),
          create(:blood_pressure,
            :with_encounter,
            patient: patient_2,
            user: user,
            facility: inactive_facility_with_bp_outside_period,
            recorded_at: date - 1.month)]
      }.flatten
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
