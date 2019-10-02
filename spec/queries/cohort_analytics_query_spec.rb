require 'rails_helper'

RSpec.describe CohortAnalyticsQuery do
  let!(:facility) { create(:facility) }
  let(:analytics) { CohortAnalyticsQuery.new(facility.registered_patients) }

  let(:jan) { Date.new(2019, 1, 1) }
  let(:march) { Date.new(2019, 3, 1) }
  let(:april) { Date.new(2019, 4, 1) }
  let(:july) { Date.new(2019, 7, 1) }
  let(:oct) { Date.new(2019, 10, 1) }

  let(:jan_registered_patients) do
    Timecop.travel(jan) do
      create_list(:patient, 15, registration_facility: facility)
    end
  end

  describe "#patient_counts" do
    it "calculates return and control patient counts in Q2 for patients registered in Q1" do
      Timecop.travel(april) do
        # 2 patients under control, 3 not controlled
        jan_registered_patients[0..1].each { |patient| create(:blood_pressure, :under_control, patient: patient, facility: facility, ) }
        jan_registered_patients[2..4].each { |patient| create(:blood_pressure, :very_high, patient: patient, facility: facility) }
      end

      expected_result = {
        registered: 15,
        followed_up: 5,
        defaulted: 10,
        controlled: 2,
        uncontrolled: 3
      }

      cohort_start = DateTime.new(2019, 1, 1).beginning_of_quarter
      cohort_end   = cohort_start.end_of_quarter

      report_start = DateTime.new(2019, 4, 1).beginning_of_quarter
      report_end   = report_start.end_of_quarter

      expect(analytics.patient_counts(cohort_start, cohort_end, report_start, report_end)).to eq(expected_result)
    end

    it "calculates return and control patient counts in Feb-Mar for patients registered in Jan" do
      Timecop.travel(march) do
        # 3 patients under control, 5 not controlled
        jan_registered_patients[0..2].each { |patient| create(:blood_pressure, :under_control, patient: patient, facility: facility, ) }
        jan_registered_patients[3..7].each { |patient| create(:blood_pressure, :very_high, patient: patient, facility: facility) }
      end

      expected_result = {
        registered: 15,
        followed_up: 8,
        defaulted: 7,
        controlled: 3,
        uncontrolled: 5
      }

      cohort_start = DateTime.new(2019, 1, 1).beginning_of_month
      cohort_end   = cohort_start.end_of_month

      report_start = DateTime.new(2019, 2, 1).beginning_of_month
      report_end   = DateTime.new(2019, 3, 1).end_of_month

      expect(analytics.patient_counts(cohort_start, cohort_end, report_start, report_end)).to eq(expected_result)
    end
  end
end
