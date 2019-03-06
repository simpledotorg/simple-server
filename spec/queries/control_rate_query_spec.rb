require 'rails_helper'

RSpec.describe PatientsReturningDuringPeriodQuery do
  let(:from_time) { 1.month.ago }
  let(:to_time) { Date.today }

  let(:facilities) { create_list :facility, 2 }

  let!(:hypertensive_patients_registered_9_months_ago) do
    facilities.flat_map do |facility|
      patients = create_list_in_period(:patient, 5, from_time: from_time - 9.months, to_time: to_time - 9.months, registration_facility: facility)
      patients.each do |patient|
        create_in_period(
          :blood_pressure,
          trait: :hypertensive, from_time: from_time - 9.months, to_time: to_time - 9.months - 1.day,
          patient: patient, facility: facility)
      end
      patients
    end
  end

  let!(:patients_under_control_in_period) do
    patients_under_control_in_period = hypertensive_patients_registered_9_months_ago.sample(4)
    patients_under_control_in_period.each do |patient|
      create_in_period(
        :blood_pressure,
        trait: :under_control, from_time: from_time, to_time: to_time,
        patient: patient, facility: patient.registration_facility)
    end
    patients_under_control_in_period
  end

  describe '#call' do
    it 'returns the number of unique patients registerted at a list of facilities' do
      results = ControlRateQuery.new(patients: Patient.all).for_period(from_time: from_time, to_time: to_time)

      expect(results)
        .to eq(control_rate: 40,
               hypertensive_patients_in_cohort: 10,
               patients_under_control_in_period: 4)
    end
  end
end