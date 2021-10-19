require "rails_helper"

RSpec.describe BloodPressuresPerFacilityPerDay, type: :model do
  around do |example|
    with_reporting_time_zone { example.run }
  end

  describe "Associations" do
    it { should belong_to(:facility) }
  end

  describe "Materialized view query" do
    let!(:facility_with_bp) { create(:facility) }
    let!(:patient) { create(:patient, registration_facility: facility_with_bp) }
    let!(:patient_2) { create(:patient, registration_facility: facility_with_bp) }
    let!(:facility_without_bp) { create(:facility) }

    let!(:days) do
      [1, 2].map { |n| n.days.ago }
    end

    let!(:blood_pressures) do
      days.map { |day|
        create_list(:blood_pressure, 2, facility: facility_with_bp, recorded_at: day, patient: patient)
      } + [create(:blood_pressure, facility: facility_with_bp, recorded_at: days.first, patient: patient_2)]
    end

    before do
      described_class.refresh
    end

    it "returns a row per facility per day" do
      expect(described_class.all.count).to eq(2)
    end

    it "has two bps counted on the first day" do
      expect(described_class.where(year: 1.day.ago.year, day: 1.day.ago.yday).first.bp_count).to eq(2)
    end

    it "has one bp on the second day" do
      expect(described_class.where(year: 2.day.ago.year, day: 2.day.ago.yday).first.bp_count).to eq(1)
    end

    it "counts blood pressures of only patients who are diagnosed hypertensive" do
      patient_with_hypertension_no = create(:patient, :without_hypertension, registration_facility: facility_with_bp)
      create(:blood_pressure, facility: facility_with_bp, recorded_at: days.first, patient: patient_with_hypertension_no)
      described_class.refresh

      expect(described_class.where(year: 1.day.ago.year, day: 1.day.ago.yday).first.bp_count).to eq(2)
    end

    it "doesn't have a row for facility_without_bp" do
      expect(described_class.all.pluck(:facility_id)).not_to include(facility_without_bp.id)
    end
  end
end
