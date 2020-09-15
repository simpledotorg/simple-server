require "rails_helper"

RSpec.describe PatientListDownloadJob, type: :job do
  include ActiveJob::TestHelper

  let!(:admin) { create(:admin) }
  let!(:facility) { create(:facility) }

  context "when with_medication_history is false" do
    it "should queue a PatientsExporter export" do
      expect(PatientsExporter).to receive(:csv)
      PatientListDownloadJob.perform_now(admin.email, "facility", {facility_id: facility.id}, with_medication_history: false)
    end

    it "should queue a PatientsExporter export by default" do
      expect(PatientsExporter).to receive(:csv)
      PatientListDownloadJob.perform_now(admin.email, "facility", {facility_id: facility.id})
    end

    it "should work for FacilityGroup" do
      facility_group = create(:facility_group)
      facility = create(:facility, facility_group: facility_group)
      patients = create_list(:patient, 2, registration_facility: facility)
      expect(PatientsExporter).to receive(:csv).with(patients)
      PatientListDownloadJob.perform_now(admin.email, "facility_group", {id: facility_group.id})
    end
  end

  context "when with_medication_history is true" do
    it "should queue a PatientsWithHistoryExporter export" do
      expect(PatientsWithHistoryExporter).to receive(:csv)
      PatientListDownloadJob.perform_now(admin.email, "facility", {facility_id: facility.id}, with_medication_history: true)
    end
  end
end
