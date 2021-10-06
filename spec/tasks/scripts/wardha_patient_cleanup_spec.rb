require "rails_helper"
require "tasks/scripts/wardha_patient_cleanup"

RSpec.describe WardhaPatientCleanup do
  describe "#discard" do
    it "deletes patients in the CSV" do
      patients = [create(:patient, id: "14f9893e-d4b1-48c6-be68-e199fcdd723b"),
        create(:patient, id: "fa50dcea-bb6e-483a-9a0d-63e4c9129f98")]
      blood_pressures = patients.map { |patient| create(:blood_pressure, patient: patient) }

      described_class.discard

      expect(patients.map(&:reload).map(&:deleted_at)).to all be_present
      expect(blood_pressures.map(&:reload).map(&:deleted_at)).to all be_present
    end
  end

  describe "#deduplicate" do
    it "kicks off the deduplication task" do
      patients = [create(:patient, id: "0373ae28-64dc-4352-b7f5-6c26c95f11ac"),
        create(:patient, id: "f7f333f1-dfc9-4f62-b23b-9e5e4dc63127")]

      expect(PatientDeduplication::Runner).to receive(:new).with(patients.pluck(:id)).once.and_call_original

      described_class.deduplicate
    end
  end
end
