require 'rails_helper'

RSpec.describe Analytics::FacilityAnalytics do
  let(:organization) { create :organization }
  let(:facility_group) { create :facility_group, organization: organization }
  let(:facility) { create :facility, facility_group: facility_group }
  let(:from_time) { 1.month.ago }
  let(:to_time) { Date.today }

  let!(:newly_enrolled_patients) do
    create_list_in_period(:patient, 5, from_time: from_time, to_time: to_time, registration_facility: facility)
  end

  let!(:non_returning_patients) do
    create_list_in_period(:patient, 2, from_time: Time.new(0), to_time: from_time, registration_facility: facility)
  end

  let!(:non_returning_hypertensive_patients) do
    patients = create_list_in_period(:patient, 10, from_time: Time.new(0), to_time: from_time, registration_facility: facility)
    patients.each do |patient|
      create_in_period(
        :blood_pressure,
        trait: :hypertensive, from_time: patient.device_created_at, to_time: from_time,
        patient: patient, facility: facility)
    end
    patients
  end

  let!(:returning_patients) do
    patients = create_list_in_period(:patient, 1, from_time: Time.new(0), to_time: from_time, registration_facility: facility)
    patients.each do |patient|
      create_in_period(
        :blood_pressure,
        trait: :under_control, from_time: from_time, to_time: to_time,
        patient: patient, facility: facility)
    end
    patients
  end

  let(:facility_analytics) { Analytics::FacilityAnalytics.new(facility, from_time: from_time, to_time: to_time) }

  describe '#newly_entrolled_users' do
    it 'returns a list of newly entrolled patients' do
      expect(facility_analytics.newly_enrolled_patients).to match_array(newly_enrolled_patients)
    end
  end

  describe '#returning_patients' do
    it 'returns a list of returning patients' do
      expect(facility_analytics.returning_patients).to match_array(returning_patients)
      expect(facility_analytics.returning_patients).not_to include(non_returning_patients)
      expect(facility_analytics.returning_patients).not_to include(non_returning_hypertensive_patients)
    end
  end

  describe '#non_returning_hypertensive_patients' do
    it 'returns a list of hypertensive patients that do not have a blood pressure recording in period' do
      expect(facility_analytics.non_returning_hypertensive_patients).to match_array(non_returning_hypertensive_patients)
    end
  end

  describe '#non_returning_hypertensive_patients_per_month' do
    it 'returns the number of non returning hypertensive patients per month' do
      expected_counts = {
        to_time - 1.month => 10,
        to_time - 2.month => 10,
        to_time - 3.month => 10
      }.map { |k, v| [k.at_beginning_of_month, v] }.to_h
      expect(facility_analytics.non_returning_hypertensive_patients_per_month(4)).to include(expected_counts)
    end
  end

  describe 'control rate calculations' do
    let!(:hypertensive_patients_registered_9_months_ago) do
      patients = create_list_in_period(:patient, 10, from_time: from_time - 9.months, to_time: to_time - 9.months, registration_facility: facility)
      patients.each do |patient|
        create_in_period(
          :blood_pressure,
          trait: :hypertensive, from_time: from_time - 9.months, to_time: to_time - 9.months,
          patient: patient, facility: facility)
      end
      patients
    end

    let!(:patients_under_control_in_period) do
      patients_under_control_in_period = hypertensive_patients_registered_9_months_ago.sample(7)
      patients_under_control_in_period.each do |patient|
        create_in_period(
          :blood_pressure,
          trait: :under_control, from_time: from_time, to_time: to_time,
          patient: patient, facility: patient.registration_facility)
      end
      patients_under_control_in_period
    end

    describe '#control_rate' do
      it 'returns the control rate of the period' do
        expect(facility_analytics.control_rate).to eq(70)
      end
    end
  end
end
