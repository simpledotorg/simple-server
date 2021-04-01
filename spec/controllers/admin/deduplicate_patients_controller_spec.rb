require "rails_helper"

RSpec.describe Admin::DeduplicatePatientsController, type: :controller do
  context "#merge" do
    it "merges patients given their IDs" do
      patients = [create(:patient, full_name: "Patient one"), create(:patient, full_name: "Patient two")]
      admin = create(:admin, :manager, :with_access, resource: patients.first.assigned_facility)
      sign_in(admin.email_authentication)

      post :merge, params: {duplicate_patients: patients.map(&:id)}

      patients.each(&:reload)
      expect(patients).to all be_discarded
      expect(Patient.pluck(:merged_by_user_id)).to all eq admin.id
      expect(Patient.count).to eq 1
    end

    it "returns unauthorized when none of the patient IDs is accessible by the user" do
      patients = [create(:patient, full_name: "Patient one"), create(:patient, full_name: "Patient two")]
      admin = create(:admin, :manager, :with_access, resource: create(:facility))
      sign_in(admin.email_authentication)

      post :merge, params: {duplicate_patients: patients.map(&:id)}

      expect(response.status).to eq(401)
    end

    it "handles any errors with merge" do
      admin = create(:admin, :power_user)
      sign_in(admin.email_authentication)

      allow_any_instance_of(PatientDeduplication::Deduplicator).to receive(:errors).and_return(["Some error"])
      patients = [create(:patient, full_name: "Patient one"), create(:patient, full_name: "Patient two")]

      post :merge, params: {duplicate_patients: patients.map(&:id)}
      expect(flash.alert).to be_present
      expect(Patient.count).to eq 2
    end
  end
end
