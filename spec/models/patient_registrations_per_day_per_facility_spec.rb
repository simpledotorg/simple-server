require 'rails_helper'

RSpec.describe PatientRegistrationsPerDayPerFacility, type: :model do
  describe 'Associations' do
    it { should belong_to(:facility) }
  end

  describe 'SQL view definition' do
    let!(:facilities) { create_list(:facility, 2) }
    let!(:days) do
      [1, 10, 365].map { |n| n.days.ago }
    end
    let!(:patients) { create_list(:patient, 2) }

    let!(:blood_pressures) do
      facilities.map do |facility|
        days.map do |day|
          patients.map do |patient|
            create_list(:blood_pressure, 2, facility: facility, recorded_at: day, patient: patient)
          end
        end
      end.flatten
    end

    let!(:query_results) do
      described_class.refresh
      described_class.all
    end

    it 'should return a row per facility per day' do
      expect(query_results.count).to eq(6)
    end

    it 'should return at least one row per facility' do
      expect(query_results.pluck(:facility_id).uniq).to match_array(facilities.map(&:id))
    end
  end
end
