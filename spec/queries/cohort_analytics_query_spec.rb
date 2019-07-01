require 'rails_helper'

RSpec.describe CohortAnalyticsQuery do
  let!(:facility) { create(:facility) }
  let(:analytics) { CohortAnalyticsQuery.new(facility.patients) }

  let(:q1) { Date.new(2019, 1, 1) }
  let(:q2) { Date.new(2019, 4, 1) }
  let(:q3) { Date.new(2019, 7, 1) }
  let(:q4) { Date.new(2019, 10, 1) }

  before do
    # register 15 patients and record blood pressures in q1
    q1_registered_patients = []
    Timecop.travel(q1) do
      q1_registered_patients = create_list(:patient, 15, registration_facility: facility)
      q1_registered_patients.each { |patient| create(:blood_pressure, :very_high, patient: patient, facility: facility) }
    end

    # register 20 patients and record blood pressures in q1
    q2_registered_patients = []
    Timecop.travel(q2) do
      q2_registered_patients = create_list(:patient, 20, registration_facility: facility)
      q2_registered_patients.each { |patient| create(:blood_pressure, :very_high, patient: patient, facility: facility) }
    end

    # record controlled blood pressures for patients in q3
    Timecop.travel(q3) do
      # 2 q1 patients under control, 3 not controlled
      q1_registered_patients[0..1].each { |patient| create(:blood_pressure, :under_control, patient: patient, facility: facility, ) }
      q1_registered_patients[2..4].each { |patient| create(:blood_pressure, :very_high, patient: patient, facility: facility) }

      # 3 q2 patients under control, 4 not controlled
      q2_registered_patients[0..2].each { |patient| create(:blood_pressure, :under_control, patient: patient, facility: facility, ) }
      q2_registered_patients[3..6].each { |patient| create(:blood_pressure, :very_high, patient: patient, facility: facility) }
    end
  end

  describe "#patient_counts" do
    it "calculates return and control patient counts in Q3 for patients registered in Q1" do
      expected_result = {
        registered: 15,
        followed_up: 5,
        defaulted: 10,
        controlled: 2,
        uncontrolled: 3
      }

      expect(analytics.patient_counts(year: 2019, quarter: 3)).to eq(expected_result)
    end

    it "calculates return and control patient counts in Q3 for patients registered in Q2" do
      expected_result = {
        registered: 20,
        followed_up: 7,
        defaulted: 13,
        controlled: 3,
        uncontrolled: 4
      }

      expect(analytics.patient_counts(year: 2019, quarter: 3, quarters_previous: 1)).to eq(expected_result)
    end
  end
end
