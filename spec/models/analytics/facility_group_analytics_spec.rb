require 'rails_helper'

RSpec.describe Analytics::FacilityGroupAnalytics do
  let(:facility_group) { create :facility_group }
  let(:owner) { create :admin, :owner }
  let(:facilities) { create_list :facility, 2, facility_group: facility_group }
  let(:from_time) { 1.month.ago }
  let(:to_time) { Date.today }

  let!(:newly_enrolled_patients) do
    facilities.flat_map do |facility|
      create_list_in_period(:patient, 3, from_time: from_time, to_time: to_time, registration_facility: facility)
    end
  end

  let!(:non_returning_patients) do
    facilities.flat_map do |facility|
      create_list_in_period(:patient, 2, from_time: Time.new(0), to_time: from_time, registration_facility: facility)
    end
  end

  let!(:non_returning_hypertensive_patients) do
    facilities.flat_map do |facility|
      patients = create_list_in_period(:patient, 2, from_time: Time.new(0), to_time: from_time, registration_facility: facility)
      patients.each do |patient|
        create_in_period(
          :blood_pressure,
          trait: :hypertensive, from_time: patient.device_created_at, to_time: from_time - 1.day,
          patient: patient, facility: facility)
      end
      patients
    end
  end

  let!(:returning_patients) do
    facilities.flat_map do |facility|
      patients = create_list_in_period(:patient, 2, from_time: Time.new(0), to_time: from_time, registration_facility: facility)
      patients.each do |patient|
        create_in_period(:blood_pressure, from_time: from_time, to_time: to_time, patient: patient, facility: facility)
      end
      patients
    end
  end

  let!(:hypertensive_patients_registered_9_months_ago) do
    facilities.flat_map do |facility|
      patients = create_list_in_period(:patient, 2, from_time: from_time - 9.months, to_time: to_time - 9.months, registration_facility: facility)
      patients.each do |patient|
        create_in_period(
          :blood_pressure,
          trait: :hypertensive, from_time: from_time - 9.months, to_time: to_time - 9.months,
          patient: patient, facility: facility)
      end
      patients
    end
  end

  let!(:patients_under_control_in_period) do
    patients_under_control_in_period = hypertensive_patients_registered_9_months_ago.sample(2)
    patients_under_control_in_period.each do |patient|
      create_in_period(
        :blood_pressure,
        trait: :under_control, from_time: from_time, to_time: to_time,
        patient: patient, facility: patient.registration_facility)
    end
    patients_under_control_in_period
  end

  let(:facility_group_analytics) { Analytics::FacilityGroupAnalytics.new(facility_group, from_time: from_time, to_time: to_time) }

  describe '#newly_entrolled_users' do
    it 'returns a list of newly entrolled patients' do
      expect(facility_group_analytics.newly_enrolled_patients).to match_array(newly_enrolled_patients)
    end
  end

  describe '#returning_patients' do
    it 'returns a list of returning patients' do
      expect(facility_group_analytics.returning_patients).to match_array(returning_patients)
      expect(facility_group_analytics.returning_patients).not_to include(non_returning_patients)
      expect(facility_group_analytics.returning_patients).not_to include(non_returning_hypertensive_patients)
    end
  end

  describe '#non_returning_hypertensive_patients' do
    it 'returns a list of hypertensive patients that do not have a blood pressure recording in period' do
      expect(facility_group_analytics.non_returning_hypertensive_patients).to match_array(non_returning_hypertensive_patients)
    end
  end

  describe '#non_returning_hypertensive_patients_per_month' do
    it 'returns the number of non returning hypertensive patients per month' do
      expected_counts = {
        to_time - 1.month => 6,
        to_time - 2.month => 6,
        to_time - 3.month => 6
      }.map { |k, v| [k.at_beginning_of_month, v] }
      expect(facility_group_analytics.non_returning_hypertensive_patients_per_month(4)).to include(*expected_counts)
    end
  end

  describe '#control_rate' do
    it 'returns the control rate of the period' do
      expect(facility_group_analytics.control_rate).to eq(50)
    end
  end

  xdescribe '#control_rate_per_month' do
    it 'returns the control rate per month' do
    end
  end
end