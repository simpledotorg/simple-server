require 'rails_helper'

RSpec.describe PatientsReturningDuringPeriodQuery do
  let(:from_time) { Date.new(2019, 1, 1) }
  let(:to_time) { Date.new(2019, 3, 31) }
  let(:one_year_ago) { Date.new(2018, 1, 1) }

  describe '#call' do
    let!(:old_patients) do
      Timecop.travel(one_year_ago) { create_list(:patient, 5) }
    end

    let!(:new_patients) do
      Timecop.travel(from_time) { create_list(:patient, 3) }
    end

    let!(:returning_patients) { old_patients.take(3) }

    before :each do
      Timecop.travel(from_time) do
        returning_patients.each { |patient| create(:blood_pressure, patient: patient) }
        new_patients.each { |patient| create(:blood_pressure, patient: patient) }
      end
      CachedLatestBloodPressure.refresh
    end

    it 'returns the list of the patients that have returned in the period' do
      results = PatientsReturningDuringPeriodQuery.new(patients: Patient.all, from_time: from_time, to_time: to_time).call

      expect(results).to match_array(returning_patients)
      expect(results).not_to include(old_patients - returning_patients)
      expect(results).not_to include(new_patients)
    end
  end
end
