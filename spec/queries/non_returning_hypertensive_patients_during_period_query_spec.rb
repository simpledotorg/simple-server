require 'rails_helper'

RSpec.describe NonReturningHypertensivePatientsDuringPeriodQuery do
  let(:from_time) { Date.new(2019, 1, 1) }
  let(:to_time) { Date.new(2019, 3, 31) }
  let(:one_year_ago) { Date.new(2018, 1, 1) }

  describe '#non_returning_since' do
    let!(:hypertensive_patients) do
      Timecop.travel(one_year_ago) do
        patients = create_list(:patient, 5)
        patients.each do |patient|
          create(:blood_pressure, :high, patient: patient, recorded_at: Time.now)
        end
        patients
      end
    end

    let!(:returning_patients) do
      Timecop.travel(from_time) do
        hypertensive_patients.take(2).each do |patient|
          create(:blood_pressure, patient: patient, recorded_at: Time.now)
        end
      end
    end

    it 'returns number of patients who are hypertensive and have not returned since the given time ' do
      results = NonReturningHypertensivePatientsDuringPeriodQuery.new(patients: Patient.all).non_returning_since(from_time)

      expect(results).to match_array(hypertensive_patients - returning_patients)
      expect(results).not_to include(returning_patients)
    end
  end
end