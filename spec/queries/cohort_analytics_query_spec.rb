require 'rails_helper'

RSpec.describe CohortAnalyticsQuery do
  let!(:facility) { create(:facility) }
  let(:analytics) { CohortAnalyticsQuery.new(facility.registered_patients) }

  let(:jan)   { DateTime.new(2019, 1, 1) }
  let(:feb)   { DateTime.new(2019, 2, 1) }
  let(:march) { DateTime.new(2019, 3, 1) }
  let(:april) { DateTime.new(2019, 4, 1) }
  let(:may)   { DateTime.new(2019, 5, 1) }
  let(:june)  { DateTime.new(2019, 6, 1) }

  describe "#patient_counts_by_period" do
    before do
      allow(analytics).to receive(:patient_counts).and_return({})
    end

    context "monthly" do
      # June report: registered in April, visited in May-June
      # May report: registered in March, visited in April-May
      # April report: registered in Feb, visited in Mar-April

      it "correctly calculates the dates of monthly cohort reports" do
        travel_to(june) do
          analytics.patient_counts_by_period(:month, 2)
        end

        expect(analytics).to have_received(:patient_counts).with(april, april.end_of_month, may, june.end_of_month)
        expect(analytics).to have_received(:patient_counts).with(march, march.end_of_month, april, may.end_of_month)
        expect(analytics).to have_received(:patient_counts).with(feb, feb.end_of_month, march, april.end_of_month)
      end

      it "returns patient counts for the last 3 monthly cohorts" do
        expected_result = {
          [april, may] => {},
          [march, april] => {},
          [feb, march] => {}
        }

        travel_to(june) do
          expect(analytics.patient_counts_by_period(:month, 2)).to eq(expected_result)
        end
      end
    end

    context "quarterly" do
      # Q2 report: registered in Q1, visited in Q2
      # Q1 report: registered in Q4, visited in Q1

      let(:oct_prev) { DateTime.new(2018, 10, 1) }
      let(:dec_prev) { DateTime.new(2018, 12, 1) }

      it "correctly calculates the dates of quarterly cohort reports" do
        travel_to(june) do
          analytics.patient_counts_by_period(:quarter, 1)
        end

        expect(analytics).to have_received(:patient_counts).with(jan, march.end_of_quarter, april, june.end_of_quarter)
        expect(analytics).to have_received(:patient_counts).with(oct_prev, dec_prev.end_of_quarter, jan, march.end_of_quarter)
      end

      it "returns patient counts for the last 3 quarterly cohorts" do
        expected_result = {
          [jan, april] => {},
          [oct_prev, jan] => {}
        }

        travel_to(june) do
          expect(analytics.patient_counts_by_period(:quarter, 1)).to eq(expected_result)
        end
      end
    end
  end

  describe "#patient_counts" do
    let!(:jan_registered_patients) do
      travel_to(jan) do
        create_list(:patient, 15, registration_facility: facility)
      end
    end

    it "calculates return and control patient counts in Q2 for patients registered in Q1" do
      travel_to(april) do
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
      travel_to(march) do
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
