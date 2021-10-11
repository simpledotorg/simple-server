require "rails_helper"

RSpec.describe Admin::DeduplicatePatientsController, type: :controller do
  context "#show" do
    it "shows patients accessible by the user" do
      patient = create(:patient, full_name: "Patient one")
      patient_passport_id = patient.business_identifiers.first.identifier

      patient_dup = create(:patient, full_name: "Patient one dup")
      patient_dup.business_identifiers.first.update(identifier: patient_passport_id)

      admin = create(:admin, :manager, :with_access, resource: patient.assigned_facility)
      sign_in(admin.email_authentication)

      get :show

      expect(assigns(:patients)).to contain_exactly(patient, patient_dup)
    end

    it "omits patients not accessible by the user" do
      patient = create(:patient, full_name: "Patient one")
      patient_passport_id = patient.business_identifiers.first.identifier

      patient_dup = create(:patient, full_name: "Patient one dup")
      patient_dup.business_identifiers.first.update(identifier: patient_passport_id)

      admin = create(:admin, :manager, :with_access, resource: create(:facility))
      sign_in(admin.email_authentication)

      get :show

      expect(assigns(:patients)).to be_empty
    end

    it "returns unauthorized when the user does not have any managerial roles" do
      admin = create(:admin, :viewer_all)
      sign_in(admin.email_authentication)

      get :show
      expect(response.status).to eq(302)
      expect(flash[:alert]).to eq("You are not authorized to perform this action.")
    end
  end

  context "#merge" do
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
