require 'rails_helper'

RSpec.describe NonReturningHypertensivePatientsDuringPeriodQuery do
  let(:from_time) { 1.month.ago }
  let(:to_time) { Date.today }

  let(:facilities) { create_list :facility, 2 }

  describe '#call' do
    it 'returns the number of unique patients registerted at a list of facilities' do
      hypertensive_patients = facilities.flat_map do |facility|
        create_list_in_period(
          :patient, 5,
          from_time: 1.year.ago, to_time: from_time - 1.day,
          registration_facility: facility)
      end

      hypertensive_patients.each do |patient|
        create_in_period(
          :blood_pressure,
          trait: :hypertensive, from_time: 1.year.ago, to_time: from_time - 1.day,
          patient: patient, facility: patient.registration_facility)
      end

      returning_patients = hypertensive_patients.sample(3)
      returning_patients.each do |patient|
        create_in_period(
          :blood_pressure,
          trait: :under_control, from_time: from_time, to_time: to_time,
          patient: patient, facility: patient.registration_facility)
      end

      results = NonReturningHypertensivePatientsDuringPeriodQuery.new(facilities: facilities).non_returning_since(from_time)

      expect(results).to match_array(hypertensive_patients - returning_patients)
      expect(results).not_to include(returning_patients)
    end
  end
end