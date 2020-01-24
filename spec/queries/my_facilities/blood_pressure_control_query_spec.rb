require 'rails_helper'

RSpec.describe MyFacilities::BloodPressureControlQuery do
  include QuarterHelper

  context 'BP control queries for quarterly cohorts' do
    let!(:current_quarter) { quarter(Time.current) }
    let!(:current_year) { Time.current.year }
    let!(:facility) { create(:facility) }

    let!(:current_quarter_start) { Time.current.beginning_of_quarter }
    let!(:user) { create(:user) }
    let!(:cohort_range) do
      ((current_quarter_start - 3.months).to_date..(current_quarter_start - 3.months).end_of_quarter.to_date).to_a
    end

    let!(:current_quarter_range) do
      (current_quarter_start.to_date..Time.current.to_date).to_a
    end

    let!(:patients_with_controlled_bp) do
      (1..2).map do
        create(:patient, recorded_at: cohort_range.sample, registration_facility: facility, registration_user: user)
      end
    end

    let!(:patients_with_uncontrolled_bp) do
      (1..2).map do
        create(:patient, recorded_at: cohort_range.sample, registration_facility: facility, registration_user: user)
      end
    end

    let!(:patients_with_missed_visit) do
      (1..2).map do
        create(:patient, recorded_at: cohort_range.sample, registration_facility: facility, registration_user: user)
      end
    end

    let!(:controlled_blood_pressures) do
      patients_with_controlled_bp.map do |patient|
        create(:blood_pressure, :under_control, facility: facility, patient: patient, recorded_at: current_quarter_range.sample, user: user)
      end
    end

    let!(:uncontrolled_blood_pressures) do
      patients_with_uncontrolled_bp.map do |patient|
        create(:blood_pressure, :high, facility: facility, patient: patient, recorded_at: current_quarter_range.sample, user: user)
      end
    end

    before do
      LatestBloodPressuresPerPatientPerMonth.refresh
      LatestBloodPressuresPerPatientPerQuarter.refresh
    end

    describe '#cohort_registrations' do
      specify { expect(described_class.new(quarter: current_quarter, year: current_year, facilities: Facility.all).cohort_registrations.count).to eq(6) }
    end

    describe '#cohort_controlled_bps' do
      specify { expect(described_class.new(quarter: current_quarter, year: current_year, facilities: Facility.all).cohort_controlled_bps.count).to eq(2) }
    end

    describe '#cohort_uncontrolled_bps' do
      specify { expect(described_class.new(quarter: current_quarter, year: current_year, facilities: Facility.all).cohort_uncontrolled_bps.count).to eq(2) }
    end
  end

  context 'BP control queries for monthly cohorts' do
    let!(:current_month) { Time.current.month }
    let!(:current_year) { Time.current.year }
    let!(:facility) { create(:facility) }

    let!(:current_month_start) { Time.current.beginning_of_month }
    let!(:user) { create(:user) }
    let!(:cohort_range) do
      ((current_month_start - 2.months).to_date..(current_month_start - 2.months).end_of_month.to_date).to_a
    end

    let!(:bp_recorded_range) do
      ((current_month_start - 1.months).to_date..Time.current.to_date).to_a
    end

    let!(:current_month_range) do
      (current_month_start.to_date..Time.current.to_date).to_a
    end

    let!(:previous_month_range) do
      ((current_month_start - 1.months).to_date..(current_month_start - 1.months).end_of_month.to_date).to_a
    end

    let!(:patients_with_controlled_bp) do
      (1..2).map do
        create(:patient, recorded_at: cohort_range.sample, registration_facility: facility, registration_user: user)
      end
    end

    let!(:patients_with_uncontrolled_bp) do
      (1..2).map do
        create(:patient, recorded_at: cohort_range.sample, registration_facility: facility, registration_user: user)
      end
    end

    let!(:patients_with_missed_visit) do
      (1..2).map do
        create(:patient, recorded_at: cohort_range.sample, registration_facility: facility, registration_user: user)
      end
    end

    let!(:controlled_blood_pressures) do
      patients_with_controlled_bp.map do |patient|
        create(:blood_pressure, :under_control, facility: facility, patient: patient, recorded_at: current_month_range.sample, user: user)
        create(:blood_pressure, :under_control, facility: facility, patient: patient, recorded_at: previous_month_range.sample, user: user)
      end
    end

    let!(:uncontrolled_blood_pressures) do
      patients_with_uncontrolled_bp.map do |patient|
        create(:blood_pressure, :high, facility: facility, patient: patient, recorded_at: bp_recorded_range.sample, user: user)
      end
    end

    before do
      LatestBloodPressuresPerPatientPerMonth.refresh
    end

    describe '#cohort_registrations' do
      specify { expect(described_class.new(month: current_month, year: current_year, period: :month, facilities: Facility.all).cohort_registrations.count).to eq(6) }
    end

    describe '#cohort_controlled_bps' do
      it 'should do abc' do
        expect(described_class.new(month: current_month, year: current_year, period: :month, facilities: Facility.all).cohort_controlled_bps.count).to eq(2)
      end
    end

    describe '#cohort_uncontrolled_bps' do
      specify { expect(described_class.new(month: current_month, year: current_year, period: :month, facilities: Facility.all).cohort_uncontrolled_bps.count).to eq(2) }
    end
  end
end