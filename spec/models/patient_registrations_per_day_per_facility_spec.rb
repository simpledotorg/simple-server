require "rails_helper"

RSpec.describe PatientRegistrationsPerDayPerFacility, type: :model do
  describe "Associations" do
    it { should belong_to(:facility) }
  end

  describe "SQL view definition" do
    let!(:facilities) { create_list(:facility, 2) }
    let!(:days) do
      [1, 10, 365].map { |n| n.days.ago }
    end

    let!(:patients) do
      facilities.map { |facility|
        days.map do |day|
          create(:patient, registration_facility: facility, recorded_at: day)
        end
      }.flatten
    end

    let!(:patients_with_hypertension_no) do
      facilities.map do |facility|
        create(:patient, :without_hypertension, registration_facility: facility, recorded_at: 1.days.ago)
      end
    end

    let!(:query_results) do
      described_class.refresh
      described_class.all
    end

    it "should return a row per facility per day" do
      expect(query_results.count).to eq(6)
    end

    it "should return at least one row per facility" do
      expect(query_results.pluck(:facility_id).uniq).to match_array(facilities.map(&:id))
    end

    it "counts only patients who are diagnosed hypertensive" do
      expect(query_results.pluck(:registration_count).uniq).to eq([1])
    end
  end
end
