require "rails_helper"

RSpec.describe Admin::DeduplicatePatientsController, type: :controller do
  context "#merge" do
    it "merges patients given their IDs" do
      admin = create(:admin, :power_user)
      sign_in(admin.email_authentication)

      patients = [create(:patient, full_name: "Patient one"), create(:patient, full_name: "Patient two")]

      post :merge, params: {duplicate_patients: patients.map(&:id)}

      patients.each(&:reload)
      expect(patients).to all be_discarded
      expect(Patient.pluck(:merged_by_user_id)).to all eq admin.id
      expect(Patient.count).to eq 1
    end
  end
end
