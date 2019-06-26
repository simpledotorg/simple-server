require 'rails_helper'

RSpec.describe CohortAnalyticsQuery do
  let!(:facility) { create(:facility) }
  let(:analytics) { CohortAnalyticsQuery.new(facility.patients, 2019, 3) }

  let(:q1) { Date.new(2019, 1, 1) }
  let(:q2) { Date.new(2019, 4, 1) }
  let(:q3) { Date.new(2019, 7, 1) }
  let(:q4) { Date.new(2019, 10, 1) }

  before do
    # register patients and record blood pressures in q1
    q1_registered_patients = []
    q2_registered_patients = []

    Timecop.travel(q1) do
      q1_registered_patients = create_list(:patient, 10, registration_facility: facility)
      q1_registered_patients.each { |patient| create(:blood_pressure, :very_high, patient: patient, facility: facility) }
    end

    # record controlled blood pressures for patients in q3
    Timecop.travel(q3) do
      # 1 patients under control
      q1_registered_patients[0..1].each { |patient| create(:blood_pressure, :under_control, patient: patient, facility: facility, ) }

      # 2 patients not under control
      q1_registered_patients[2..4].each { |patient| create(:blood_pressure, :very_high, patient: patient, facility: facility) }
    end
  end

  describe "#patient_counts" do
    it "calculates return and control patient counts in Q3 for patients registered in Q1" do
      expected_result = {
        registered_patients: 10,
        defaulted_patients: 7,
        follow_up_patients: 3,
        controlled_patients: 1,
        uncontrolled_patients: 2
      }

      expect(analytics.patient_counts).to eq(expected_result)
    end
  end
end
