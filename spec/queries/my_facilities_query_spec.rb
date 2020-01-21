require 'rails_helper'

RSpec.describe MyFacilitiesQuery do

  describe '#inactive_facilities' do
    let!(:active_facility) { create(:facility) }
    let!(:inactive_facility) { create (:facility) }
    let!(:inactive_facility_with_zero_bps) { create (:facility) }
    let!(:blood_pressures_for_active_facility) { create_list(:blood_pressure, 10, facility: active_facility, recorded_at: Time.current) }
    let!(:blood_pressures_for_inactive_facility) { create_list(:blood_pressure, 9, facility: inactive_facility, recorded_at: Time.current) }
    let!(:encounters) do
      (blood_pressures_for_active_facility + blood_pressures_for_inactive_facility).each { |record|
        create(:encounter, :with_observables, patient: record.patient, observable: record, facility: record.facility) }
    end

    it 'should return only inactive facilities' do
      facility_ids = [active_facility.id, inactive_facility.id, inactive_facility_with_zero_bps.id]
      expect(MyFacilitiesQuery.new.inactive_facilities(Facility.where(id: facility_ids)))
        .to match_array([inactive_facility, inactive_facility_with_zero_bps])
    end
  end

  context 'BP control queries for quarterly cohorts' do
    let!(:cohort_quarter) { quarter(Time.current) }
    let!(:cohort_year) { Time.current.year }
    let!(:facility) { create(:facility) }
    let!(:bp_recorded_at) { Time.current - 3.months }
    let!(:patient_with_controlled_bp) { create(:patient, recorded_at: bp_recorded_at, registration_facility: facility) }
    let!(:patient_with_uncontrolled_bp) { create(:patient, recorded_at: bp_recorded_at, registration_facility: facility) }
    let!(:patient_with_missed_visit) { create(:patient, recorded_at: bp_recorded_at, registration_facility: facility) }
    let!(:controlled_blood_pressure) { create(:blood_pressure, :under_control, facility: facility, patient: patient_with_controlled_bp, recorded_at: Time.current) }
    let!(:uncontrolled_blood_pressure) { create(:blood_pressure, :high, facility: facility, patient: patient_with_uncontrolled_bp, recorded_at: Time.current) }

    before do
      LatestBloodPressuresPerPatientPerMonth.refresh
    end

    describe '#cohort_registrations' do
      specify { expect(MyFacilitiesQuery.new(quarter: cohort_quarter, year: cohort_year).cohort_registrations(Facility.all).count).to eq(3) }
    end

    describe '#cohort_controlled_bps' do
      specify { expect(MyFacilitiesQuery.new(quarter: cohort_quarter, year: cohort_year).cohort_controlled_bps(Facility.all).count).to eq(1) }
    end

    describe '#cohort_uncontrolled_bps' do
      specify { expect(MyFacilitiesQuery.new(quarter: cohort_quarter, year: cohort_year).cohort_uncontrolled_bps(Facility.all).count).to eq(1) }
    end
  end

  context 'BP control queries for monthly cohorts' do
    let!(:cohort_month) { Time.current.month }
    let!(:cohort_year) { Time.current.year }
    let!(:facility) { create(:facility) }
    let!(:bp_recorded_at) { Time.current - 2.months }
    let!(:patient_with_controlled_bp) { create(:patient, recorded_at: bp_recorded_at, registration_facility: facility) }
    let!(:patient_with_uncontrolled_bp) { create(:patient, recorded_at: bp_recorded_at, registration_facility: facility) }
    let!(:patient_with_missed_visit) { create(:patient, recorded_at: bp_recorded_at, registration_facility: facility) }
    let!(:controlled_blood_pressure) { create(:blood_pressure, :under_control, facility: facility, patient: patient_with_controlled_bp, recorded_at: Time.current) }
    let!(:uncontrolled_blood_pressure) { create(:blood_pressure, :high, facility: facility, patient: patient_with_uncontrolled_bp, recorded_at: Time.current) }

    before do
      LatestBloodPressuresPerPatientPerMonth.refresh
    end

    describe '#cohort_registrations' do
      specify { expect(MyFacilitiesQuery.new(quarter: cohort_month, year: cohort_year).cohort_registrations(Facility.all).count).to eq(3) }
    end

    describe '#cohort_controlled_bps' do
      specify { expect(MyFacilitiesQuery.new(quarter: cohort_month, year: cohort_year).cohort_controlled_bps(Facility.all).count).to eq(1) }
    end

    describe '#cohort_uncontrolled_bps' do
      specify { expect(MyFacilitiesQuery.new(quarter: cohort_month, year: cohort_year).cohort_uncontrolled_bps(Facility.all).count).to eq(1) }
    end
  end
end
