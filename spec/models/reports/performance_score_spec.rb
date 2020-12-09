require "rails_helper"

describe Reports::PerformanceScore, type: :model do
  let(:period) { Period.month("July 1 2020") }
  let(:facility) { build(:facility) }
  let(:reports_result) { double("Reports::Result") }
  let(:perf_score) { Reports::PerformanceScore.new(region: facility, reports_result: reports_result, period: period) }

  describe "#overall_score" do
    it "returns a score that sums control, visits, and registration scores" do
      allow(reports_result).to receive(:controlled_patients_rate_for).with(period).and_return(40)
      allow(reports_result).to receive(:missed_visits_rate_for).with(period).and_return(60)
      allow(reports_result).to receive(:registrations_for).with(period).and_return(80)
      allow(facility).to receive(:monthly_estimated_opd_load).and_return(1000)
      expect(perf_score.overall_score).to eq(20 + 12 + 16)
    end
  end

  describe "#control_score" do
    it "returns a 50% weighted score based on control rate" do
      allow(reports_result).to receive(:controlled_patients_rate_for).with(period).and_return(40)
      expect(perf_score.control_score).to eq(20)
    end

    it "functions when control rate is 0" do
      allow(reports_result).to receive(:controlled_patients_rate_for).with(period).and_return(0)
      expect(perf_score.control_score).to eq(0)
    end

    it "functions when control rate is nil" do
      allow(reports_result).to receive(:controlled_patients_rate_for).with(period).and_return(nil)
      expect(perf_score.control_score).to eq(0)
    end
  end

  describe "#visits_score" do
    it "returns a 30% weighted score based on the inverse of the visits rate" do
      allow(reports_result).to receive(:missed_visits_rate_for).with(period).and_return(60)
      expect(perf_score.visits_score).to eq(12)
    end
  end

  describe "#visits_rate" do
    it "returns the inverse of the visits rate" do
      allow(reports_result).to receive(:missed_visits_rate_for).with(period).and_return(60)
      expect(perf_score.visits_rate).to eq(40)
    end

    it "functions when missed_visits is 0" do
      allow(reports_result).to receive(:missed_visits_rate_for).with(period).and_return(0)
      expect(perf_score.visits_rate).to eq(100)
    end

    it "functions when missed_visits is nil" do
      allow(reports_result).to receive(:missed_visits_rate_for).with(period).and_return(nil)
      expect(perf_score.visits_rate).to eq(100)
    end
  end

  describe "#registrations_score" do
    it "returns a 30% weighted score based on registration rate" do
      allow(reports_result).to receive(:registrations_for).with(period).and_return(80)
      allow(facility).to receive(:monthly_estimated_opd_load).and_return(1000)
      expect(perf_score.registrations_score).to eq(16)
    end
  end

  describe "#registrations_rate" do
    it "returns the registration rate based on registrations / target registrations" do
      allow(reports_result).to receive(:registrations_for).with(period).and_return(80)
      allow(facility).to receive(:monthly_estimated_opd_load).and_return(1000)
      expect(perf_score.registrations_rate).to eq(80)
    end

    it "functions when registrations is 0" do
      allow(reports_result).to receive(:registrations_for).with(period).and_return(0)
      allow(facility).to receive(:monthly_estimated_opd_load).and_return(1000)
      expect(perf_score.registrations_rate).to eq(0)
    end

    it "functions when registrations is nil" do
      allow(reports_result).to receive(:registrations_for).with(period).and_return(nil)
      allow(facility).to receive(:monthly_estimated_opd_load).and_return(1000)
      expect(perf_score.registrations_rate).to eq(0)
    end

    it "functions when opd_load is 0" do
      allow(reports_result).to receive(:registrations_for).with(period).and_return(80)
      allow(facility).to receive(:monthly_estimated_opd_load).and_return(0)
      expect(perf_score.registrations_rate).to eq(100)
    end

    it "functions when registrations and opd_load are both 0" do
      allow(reports_result).to receive(:registrations_for).with(period).and_return(0)
      allow(facility).to receive(:monthly_estimated_opd_load).and_return(0)
      expect(perf_score.registrations_rate).to eq(0)
    end

    it "maxes at 100 if registrations exceeds target" do
      allow(reports_result).to receive(:registrations_for).with(period).and_return(500)
      allow(facility).to receive(:monthly_estimated_opd_load).and_return(100)
      expect(perf_score.registrations_rate).to eq(100)
    end
  end

  describe "#target_registrations" do
    it "returns the target based on the estimated OPD load" do
      allow(facility).to receive(:monthly_estimated_opd_load).and_return(1000)
      expect(perf_score.target_registrations).to eq(100)
    end

    it "functions when opd_load is 0" do
      allow(facility).to receive(:monthly_estimated_opd_load).and_return(0)
      expect(perf_score.target_registrations).to eq(0)
    end
  end
end
