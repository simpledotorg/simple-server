require "rails_helper"

RSpec.describe PatientListDownloadJob, type: :job do
  include ActiveJob::TestHelper

  let!(:admin) { create(:admin) }
  let!(:facility) { create(:facility) }

  it "should work for FacilityGroup" do
    facility_group = create(:facility_group)
    facility = create(:facility, facility_group: facility_group)
    patients = create_list(:patient, 2, assigned_facility: facility)
    expect(PatientsWithHistoryExporter).to receive(:csv).with(a_collection_containing_exactly(*patients))
    described_class.perform_async(admin.email, "facility_group", {id: facility_group.id})
    described_class.drain
  end

  it "should queue a PatientsWithHistoryExporter export" do
    expect(PatientsWithHistoryExporter).to receive(:csv)
    described_class.perform_async(admin.email, "facility", {facility_id: facility.id})
    described_class.drain
  end

  context "facilities" do
    let!(:other_facility) { create(:facility) }
    let!(:assigned_patients) { create_list(:patient, 2, assigned_facility: facility) }
    let!(:registered_patients) { create_list(:patient, 2, registration_facility: facility, assigned_facility: other_facility) }

    it "should export only assigned patients" do
      expect(PatientsWithHistoryExporter).to receive(:csv).with(Patient.where(id: assigned_patients))
      described_class.perform_async(admin.email, "facility", {facility_id: facility.id})
      described_class.drain
    end
  end
end
