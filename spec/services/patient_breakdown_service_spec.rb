require "rails_helper"

RSpec.describe PatientBreakdownService do
  before do
    memory_store = ActiveSupport::Cache.lookup_store(:memory_store)
    allow(Rails).to receive(:cache).and_return(memory_store)
    Rails.cache.clear
  end

  describe ".call" do
    it "gets the patient breakdowns by status and ltfu-ness and caches it" do
      facility = create(:facility)
      another_facility = create(:facility)
      _ltfu_patient = create(:patient, :hypertension, recorded_at: 2.years.ago, registration_facility: facility)
      _not_ltfu_patient = create(:patient, :hypertension, registration_facility: facility)
      _ltfu_transferred_patient = create(:patient, :hypertension, recorded_at: 2.years.ago, status: :migrated, registration_facility: facility)
      _not_ltfu_transferred_patient = create(:patient, :hypertension, status: :migrated, registration_facility: facility)
      _dead_patient = create(:patient, :hypertension, status: :dead, registration_facility: facility)
      _not_hypertensive_patient = create(:patient, :without_hypertension, registration_facility: facility)
      _reassigned_to_facility_hypertensive_patient = create(
        :patient,
        :hypertension,
        registration_facility: another_facility,
        assigned_facility: facility
      )

      _ltfu_diabetes_patient = create(:patient, :diabetes, recorded_at: 2.years.ago, registration_facility: facility)
      _not_ltfu_diabetes_patient = create(:patient, :diabetes, registration_facility: facility)
      _ltfu_transferred_diabetes_patient = create(:patient, :diabetes, recorded_at: 2.years.ago, status: :migrated, registration_facility: facility)
      _not_ltfu_transferred_diabetes_patient = create(:patient, :diabetes, status: :migrated, registration_facility: facility)
      _dead_diabetes_patient = create(:patient, :diabetes, status: :dead, registration_facility: facility)
      _not_diabetes_patient = create(:patient, :without_diabetes, registration_facility: facility)
      _reassigned_to_facility_diabetes_patient = create(
        :patient,
        :diabetes,
        registration_facility: another_facility,
        assigned_facility: facility
      )

      refresh_views

      expected_result = {
        diabetes: {
          dead_patients: 1,
          ltfu_patients: 2,
          not_ltfu_patients: 2,
          ltfu_transferred_patients: 1,
          not_ltfu_transferred_patients: 1,
          total_registered_patients: 5,
          total_assigned_patients: 6
        },
        hypertension: {
          dead_patients: 1,
          ltfu_patients: 2,
          not_ltfu_patients: 2,
          ltfu_transferred_patients: 1,
          not_ltfu_transferred_patients: 1,
          total_registered_patients: 5,
          total_assigned_patients: 6
        }
      }
      cache_key = "#{described_class.name}/regions/facility/#{facility.region.id}"

      expect(PatientBreakdownService.call(region: facility)).to eq(expected_result)
      expect(Rails.cache.fetch(cache_key)).to eq(expected_result)
    end
  end
end
