require "rails_helper"

describe MergeDuplicatePatients do
  context "#create_new_patient_from" do
    it "creates a new patient with the right associated facilities and users" do
      facility_blue = create(:facility, block: "blue")
      patient_blue = create_regular_patient(registration_time: 2.month.ago, facility: facility_blue)
      passport_id = patient_blue.business_identifiers.first.identifier
      add_some_visits(patient_blue, 3)

      facility_red = create(:facility, facility_group: facility_blue.facility_group, block: "red")
      patient_red = create_regular_patient(registration_time: 1.month.ago, facility: facility_red)
      patient_red.business_identifiers.first.update(identifier: passport_id)
      add_some_visits(patient_red, 3)

      new_patient = described_class.new.create_new_patient_from([patient_blue, patient_red])
      expect(new_patient.recorded_at).to eq(patient_blue.recorded_at)
      expect(new_patient.registration_facility).to eq(patient_blue.registration_facility)
      expect(new_patient.registration_user).to eq(patient_blue.registration_user)
      expect(new_patient.assigned_facility).to eq(patient_red.assigned_facility)
      expect(new_patient.device_created_at).to eq(patient_blue.device_created_at)
      expect(new_patient.device_updated_at).to eq(patient_blue.device_updated_at)
      expect(new_patient).to be_valid
    end

    pending "Uses full set of prescription drugs from latest visit, and ensures history is kept" do

    end
  end
end