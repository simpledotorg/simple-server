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
  end

  context "when with_medication_history is true" do
    it "should queue a PatientsWithHistoryExporter export" do
      expect(PatientsWithHistoryExporter).to receive(:csv)
      PatientListDownloadJob.perform_now(admin.email, "facility", {facility_id: facility.id}, with_medication_history: true)
    end
  end

  context "district" do
    let!(:other_district_facility) { create(:facility, district: "Other district") }
    let!(:assigned_patients) { create_list(:patient, 2, assigned_facility: facility) }
    let!(:other_district_patients) { create_list(:patient, 2, assigned_facility: other_district_facility) }
    let!(:registered_patients) { create_list(:patient, 2, registration_facility: facility, assigned_facility: other_district_facility) }

    it "should export only assigned patients in the district" do
      expect(PatientsExporter).to receive(:csv).with(a_collection_containing_exactly(*assigned_patients))

      PatientListDownloadJob.perform_now(admin.email,
        "district",
        {district_name: facility.district,
         organization_id: facility.organization.id},
        with_medication_history: false)
    end
  end

  context "facilities" do
    let!(:other_facility) { create(:facility) }
    let!(:assigned_patients) { create_list(:patient, 2, assigned_facility: facility) }
    let!(:registered_patients) { create_list(:patient, 2, registration_facility: facility, assigned_facility: other_facility) }

    it "should export only assigned patients" do
      expect(PatientsExporter).to receive(:csv).with(Patient.where(id: assigned_patients))
      PatientListDownloadJob.perform_now(admin.email, "facility", {facility_id: facility.id}, with_medication_history: false)
    end
  end
end
