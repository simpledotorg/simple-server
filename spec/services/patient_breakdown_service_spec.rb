require "rails_helper"

RSpec.describe PatientBreakdownService do
  let!(:facility) { create(:facility) }
  let!(:ltfu_patient) { create(:patient, :hypertension, recorded_at: 2.years.ago, assigned_facility: facility) }
  let!(:not_ltfu_patient) { create(:patient, :hypertension, assigned_facility: facility) }
  let!(:ltfu_transferred_patient) { create(:patient, :hypertension, recorded_at: 2.years.ago, status: :migrated, assigned_facility: facility) }
  let!(:not_ltfu_transferred_patient) { create(:patient, :hypertension, status: :migrated, assigned_facility: facility) }
  let!(:dead_patient) { create(:patient, :hypertension, status: :dead, assigned_facility: facility) }
  let!(:not_hypertensive_patient) { create(:patient, :without_hypertension, assigned_facility: facility) }
  let!(:blood_pressures) {
    [create(:blood_pressure, recorded_at: 1.day.ago, patient: not_ltfu_patient),
      create(:blood_pressure, recorded_at: 1.day.ago, patient: not_ltfu_transferred_patient)]
  }

  let!(:memory_store) { ActiveSupport::Cache.lookup_store(:memory_store) }
  let!(:cache) { Rails.cache }

  before do
    allow(Rails).to receive(:cache).and_return(memory_store)
    Rails.cache.clear
  end

  describe ".call" do
    it "gets the patient breakdowns by status and ltfu-ness and caches it" do
      expected_result = {
        dead_patients: 1,
        ltfu_patients: 2,
        not_ltfu_patients: 2,
        ltfu_transferred_patients: 1,
        not_ltfu_transferred_patients: 1,
        total_patients: 5
      }
      cache_key = "#{described_class.name}/regions/facility/#{facility.region.id}"

      expect(PatientBreakdownService.call(region: facility)).to eq(expected_result)
      expect(Rails.cache.fetch(cache_key)).to eq(expected_result)
    end
  end
end
