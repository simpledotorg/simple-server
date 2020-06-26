require 'rails_helper'

RSpec.describe PatientListDownloadJob, type: :job do
  include ActiveJob::TestHelper

  let!(:admin) { create(:admin) }
  let!(:facility) { create(:facility) }

  context "when with_medical_history is false" do
    it "should queue a PatientsExporter export" do
      expect(PatientsExporter).to receive(:csv)
      PatientListDownloadJob.perform_now(admin.email, "facility", {facility_id: facility.id}, with_medical_history: false)
    end

    it "should queue a PatientsExporter export by default" do
      expect(PatientsExporter).to receive(:csv)
      PatientListDownloadJob.perform_now(admin.email, "facility", {facility_id: facility.id})
    end
  end

  context "when with_medical_history is true" do
    it "should queue a PatientsWithHistoryExporter export" do
      expect(PatientsWithHistoryExporter).to receive(:csv)
      PatientListDownloadJob.perform_now(admin.email, "facility", {facility_id: facility.id}, with_medical_history: true)
    end
  end
end
