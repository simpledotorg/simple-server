require 'rails_helper'

RSpec.describe ControlRateQuery do
  let(:from_time) { Date.new(2019, 1, 1) }
  let(:to_time) { Date.new(2019, 3, 31) }

  describe '#for_period' do
    before :each do
      hypertensive_patients_registered_in_cohort = Timecop.travel(from_time - ControlRateQuery::COHORT_DELTA) do
        patients = create_list(:patient, 5)
        patients.each { |patient| create(:blood_pressure, :high, patient: patient) }
        patients
      end
      hypertensive_patients_registered_in_cohort.take(2).each do |patient|
        create_in_period(
          :blood_pressure,
          trait: :under_control, from_time: from_time, to_time: to_time,
          patient: patient, facility: patient.registration_facility)
      end
    end

    it 'returns the control rate for the set of patients' do
      results = ControlRateQuery.new(patients: Patient.all).for_period(from_time: from_time, to_time: to_time)

      expect(results)
        .to eq(control_rate: 40,
               hypertensive_patients_in_cohort: 5,
               patients_under_control_in_period: 2)
    end
  end
end