require 'rails_helper'

RSpec.describe MyFacilities::OverviewQuery do

  describe '#inactive_facilities' do

    let!(:active_facility) { create(:facility) }
    let!(:inactive_facility) { create (:facility) }
    let!(:inactive_facility_with_zero_bps) { create (:facility) }
    let!(:inactive_facility_with_bp_outside_period) { create (:facility) }

    let!(:user) { create(:user, registration_facility: active_facility) }
    let!(:patient) { create(:patient, registration_user: user, registration_facility: user.facility) }
    let!(:patient_2) { create(:patient, registration_user: user, registration_facility: user.facility) }

    date_range = (0..6).map { |n| n.days.ago.beginning_of_day }

    let!(:blood_pressures_for_active_facility) do
      date_range.map do |date|
        [create(:blood_pressure, facility: active_facility, patient: patient, user: user, recorded_at: date),
        create(:blood_pressure, facility: active_facility, patient: patient_2, user: user, recorded_at: date)]
      end.flatten
    end

    let!(:blood_pressures_for_inactive_facility) do
      date_range.map do |date|
        create(:blood_pressure, facility: inactive_facility, patient: patient, user: user, recorded_at: date)
      end
    end

    let!(:blood_pressures_for_inactive_facility_with_bp_outside_period) do
      date_range.map do |date|
        [create(:blood_pressure, patient: patient, user: user, facility: inactive_facility_with_bp_outside_period, recorded_at: date - 1.month),
         create(:blood_pressure, patient: patient_2, user: user, facility: inactive_facility_with_bp_outside_period, recorded_at: date - 1.month)]
      end.flatten
    end

    let!(:encounters) do
      (blood_pressures_for_active_facility +
          blood_pressures_for_inactive_facility +
          blood_pressures_for_inactive_facility_with_bp_outside_period).each { |record|
        create(:encounter, :with_observables, patient: record.patient, observable: record, facility: record.facility) }
    end

    before do
      ActiveRecord::Base.transaction do
        ActiveRecord::Base.connection.execute("SET LOCAL TIME ZONE '#{Rails.application.config.country[:time_zone]}'")
        BloodPressuresPerFacilityPerDay.refresh
      end
    end

    it 'should return only inactive facilities' do
      facility_ids = [active_facility.id, inactive_facility.id, inactive_facility_with_zero_bps.id, inactive_facility_with_bp_outside_period.id]

      expect(described_class.new(facilities: Facility.where(id: facility_ids)).inactive_facilities.map(&:id))
          .to match_array([inactive_facility.id, inactive_facility_with_zero_bps.id, inactive_facility_with_bp_outside_period.id])
    end
  end
end
