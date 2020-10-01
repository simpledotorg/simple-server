require "rails_helper"

describe Reports::PerformanceScore, type: :model do
  let(:facility) { build(:facility, monthly_estimated_opd_load: @opd_load) }
  let(:result) do
    double("Reports::Result",
     controlled_patients_rate: { _: @control_rate },
     missed_visits_rate: { _: @missed_visits_rate },
     registrations: { _: @registrations }
    )
  end
  let(:perf_score) { Reports::PerformanceScore.new(region: facility, result: result) }

  describe "#overall_score" do
    it "returns a score that sums control, visits, and registration scores" do
      @control_rate = 40
      @missed_visits_rate = 60
      @registrations = 80
      @opd_load = 1000

      expect(perf_score.overall_score).to eq(20 + 12 + 16)
    end
  end

  describe "#control_score" do
    it "returns a 50% weighted score based on control rate" do
      @control_rate = 40
      expect(perf_score.control_score).to eq(20)
    end

    it "functions when control rate is 0" do
      @control_rate = 0
      expect(perf_score.control_score).to eq(0)
    end
  end

  describe "#visits_score" do
    it "returns a 30% weighted score based on the inverse of the visits rate" do
      @missed_visits_rate = 60
      expect(perf_score.visits_score).to eq(12)
    end
  end

  describe "#visits_rate" do
    it "returns the inverse of the visits rate" do
      @missed_visits_rate = 60
      expect(perf_score.visits_rate).to eq(40)
    end

    it "functions when missed_visits is 0" do
      @missed_visits_rate = 0
      expect(perf_score.visits_rate).to eq(100)
    end
  end

  describe "#registrations_score" do
    it "returns a 30% weighted score based on registration rate" do
      @registrations = 80
      @opd_load = 1000
      expect(perf_score.registrations_score).to eq(16)
    end
  end

  describe "#registrations_rate" do
    it "returns the registration rate based on registrations / target registrations" do
      @registrations = 80
      @opd_load = 1000
      expect(perf_score.registrations_rate).to eq(80)
    end

    it "functions when registrations is 0" do
      @registrations = 0
      @opd_load = 1000
      expect(perf_score.registrations_rate).to eq(0)
    end

    it "functions when opd_load is 0" do
      @registrations = 80
      @opd_load = 0
      expect(perf_score.registrations_rate).to eq(100)
    end

    it "functions when registrations and opd_load is 0" do
      @registrations = 0
      @opd_load = 0
      expect(perf_score.registrations_rate).to eq(0)
    end
  end

  describe "#target_registrations" do
    it "returns the target based on the estimated OPD load" do
      @opd_load = 1000
      expect(perf_score.target_registrations).to eq(100)
    end

    it "functions when opd_load is 0" do
      @opd_load = 0
      expect(perf_score.target_registrations).to eq(0)
    end
  end
end
