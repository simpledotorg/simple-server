require 'rails_helper'

RSpec.describe PatientsReturningDuringPeriodQuery do
  let(:from_time) { 1.month.ago }
  let(:to_time) { Date.today }

  let(:facilities) { create_list :facility, 2 }

  describe '#call' do
    it 'returns the number of unique patients registerted at a list of facilities' do
      old_patients = facilities.flat_map do |facility|
        create_list_in_period(
          :patient, 10,
          from_time: 1.year.ago, to_time: from_time - 1.day,
          registration_facility: facility)
      end

      returning_patients = old_patients.sample(3)
      returning_patients.each do |patient|
        create_in_period(
          :blood_pressure,
          trait: :high, from_time: from_time, to_time: to_time,
          patient: patient, facility: patient.registration_facility)
      end

      results = PatientsReturningDuringPeriodQuery.new(patients: Patient.all, from_time: from_time, to_time: to_time).call

      expect(results).to match_array(returning_patients)
      expect(results).not_to include(old_patients - returning_patients)
    end
  end
end