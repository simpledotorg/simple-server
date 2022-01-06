# frozen_string_literal: true

require "rails_helper"

describe Reports::PerformanceScore, type: :model do
  let(:period) { Period.month("July 1 2020") }
  let(:facility) { build(:facility) }
  let(:reports_result) { double("Reports::Result") }
  let(:perf_score) { Reports::PerformanceScore.new(region: facility, reports_result: reports_result, period: period) }

  describe "#letter_grade" do
    it "returns the correct grade for a given score", :aggregate_failures do
      allow(perf_score).to receive(:overall_score).and_return(100)
      expect(perf_score.letter_grade).to eq("A")

      allow(perf_score).to receive(:overall_score).and_return(75.5)
      expect(perf_score.letter_grade).to eq("A")

      allow(perf_score).to receive(:overall_score).and_return(75)
      expect(perf_score.letter_grade).to eq("B")

      allow(perf_score).to receive(:overall_score).and_return(50.5)
      expect(perf_score.letter_grade).to eq("B")

      allow(perf_score).to receive(:overall_score).and_return(50)
      expect(perf_score.letter_grade).to eq("C")

      allow(perf_score).to receive(:overall_score).and_return(25.5)
      expect(perf_score.letter_grade).to eq("C")

      allow(perf_score).to receive(:overall_score).and_return(25)
      expect(perf_score.letter_grade).to eq("D")

      allow(perf_score).to receive(:overall_score).and_return(0)
      expect(perf_score.letter_grade).to eq("D")
    end
  end

  describe "#overall_score" do
    it "returns a score that sums control, visits, and registration scores" do
      allow(perf_score).to receive(:control_score).and_return(30)
      allow(perf_score).to receive(:visits_score).and_return(20)
      allow(perf_score).to receive(:registrations_score).and_return(15)
      expect(perf_score.overall_score).to eq(65)
    end

    it "returns a 100% if a facility matches the ideal rates" do
      allow(perf_score).to receive(:adjusted_control_rate).and_return(100)
      allow(perf_score).to receive(:adjusted_visits_rate).and_return(100)
      allow(perf_score).to receive(:adjusted_registrations_rate).and_return(100)
      expect(perf_score.overall_score).to eq(100)
    end
  end

  describe "#control_score" do
    it "returns a 50% weighted score based on adjusted control rate" do
      allow(perf_score).to receive(:adjusted_control_rate).and_return(40)
      expect(perf_score.control_score).to eq(20)
    end
  end

  describe "#adjusted_control_rate" do
    it "returns 100 when the control rate matches the ideal" do
      allow(perf_score).to receive(:control_rate).and_return(70)
      expect(perf_score.adjusted_control_rate).to eq(100)
    end

    it "returns 100 when the control rate is half of the ideal" do
      allow(perf_score).to receive(:control_rate).and_return(35)
      expect(perf_score.adjusted_control_rate).to eq(50)
    end

    it "returns 100 when the control rate exceeds the ideal" do
      allow(perf_score).to receive(:control_rate).and_return(90)
      expect(perf_score.adjusted_control_rate).to eq(100)
    end

    it "returns 0 when control rate is 0" do
      allow(perf_score).to receive(:control_rate).and_return(0)
      expect(perf_score.adjusted_control_rate).to eq(0)
    end
  end

  describe "#control_rate" do
    it "returns the control rate" do
      allow(reports_result).to receive(:controlled_patients_rate).and_return({period => 20})
      expect(perf_score.control_rate).to eq(20)
    end

    it "returns 0 when control rate is empty hash" do
      allow(reports_result).to receive(:controlled_patients_rate).and_return({})
      expect(perf_score.control_rate).to eq(0)
    end
  end

  describe "#visits_score" do
    it "returns a 30% weighted score based on adjusted visits rate" do
      allow(perf_score).to receive(:adjusted_visits_rate).and_return(60)
      expect(perf_score.visits_score).to eq(18)
    end
  end

  describe "#adjusted_visits_rate" do
    it "returns 100 when the visits rate matches the ideal" do
      allow(perf_score).to receive(:visits_rate).and_return(80)
      expect(perf_score.adjusted_visits_rate).to eq(100)
    end

    it "returns 100 when the visits rate is half of the ideal" do
      allow(perf_score).to receive(:visits_rate).and_return(40)
      expect(perf_score.adjusted_visits_rate).to eq(50)
    end

    it "returns 100 when the visits rate exceeds the ideal" do
      allow(perf_score).to receive(:visits_rate).and_return(90)
      expect(perf_score.adjusted_visits_rate).to eq(100)
    end

    it "returns 0 when visits rate is 0" do
      allow(perf_score).to receive(:visits_rate).and_return(0)
      expect(perf_score.adjusted_visits_rate).to eq(0)
    end
  end

  describe "#visits_rate" do
    it "returns the inverse of the missed visits rate" do
      allow(reports_result).to receive(:missed_visits_rate).and_return({period => 60})
      expect(perf_score.visits_rate).to eq(40)
    end

    it "returns 100 when missed visits rate is 0" do
      allow(reports_result).to receive(:missed_visits_rate).and_return({period => 0})
      expect(perf_score.visits_rate).to eq(100)
    end

    it "returns 100 when missed visits rate is empty hash" do
      allow(reports_result).to receive(:missed_visits_rate).and_return({})
      expect(perf_score.visits_rate).to eq(100)
    end
  end

  describe "#registrations_score" do
    it "returns a 20% weighted score based on registrations rate" do
      allow(perf_score).to receive(:adjusted_registrations_rate).and_return(40)
      expect(perf_score.registrations_score).to eq(8)
    end
  end

  describe "#adjusted_registrations_rate" do
    it "returns 100 when the visits rate matches the ideal" do
      allow(perf_score).to receive(:registrations_rate).and_return(100)
      expect(perf_score.adjusted_registrations_rate).to eq(100)
    end

    it "returns 100 when the registrations rate is half of the ideal" do
      allow(perf_score).to receive(:registrations_rate).and_return(50)
      expect(perf_score.adjusted_registrations_rate).to eq(50)
    end

    it "returns 100 when the visits rate exceeds the ideal" do
      allow(perf_score).to receive(:registrations_rate).and_return(120)
      expect(perf_score.adjusted_registrations_rate).to eq(100)
    end

    it "returns 0 when registrations rate is 0" do
      allow(perf_score).to receive(:registrations_rate).and_return(0)
      expect(perf_score.adjusted_registrations_rate).to eq(0)
    end
  end

  describe "#registrations_rate" do
    it "returns registrations rate based on registrations / opd load" do
      allow(perf_score).to receive(:registrations).and_return(30)
      expect(perf_score.registrations_rate).to eq(10)
    end

    it "returns 100 if opd load is 0 and any registrations happen" do
      allow(facility).to receive(:monthly_estimated_opd_load).and_return(0)
      allow(perf_score).to receive(:registrations).and_return(10)
      expect(perf_score.registrations_rate).to eq(100)
    end

    it "returns 0 if opd load is 0 and no registrations happen" do
      allow(facility).to receive(:monthly_estimated_opd_load).and_return(0)
      allow(perf_score).to receive(:registrations).and_return(0)
      expect(perf_score.registrations_rate).to eq(0)
    end
  end

  describe "#registrations" do
    it "returns the registrations count" do
      allow(reports_result).to receive(:registrations).and_return(period => 20)
      expect(perf_score.registrations).to eq(20)
    end

    it "returns 0 when registrations count is empty hash" do
      allow(reports_result).to receive(:registrations).and_return({})
      expect(perf_score.registrations).to eq(0)
    end
  end
end
