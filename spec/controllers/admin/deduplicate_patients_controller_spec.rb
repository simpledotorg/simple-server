require 'rails_helper'

RSpec.describe Admin::DeduplicatePatientsController, type: :controller do
  context '#merge' do
    it 'Merges patients given their IDs' do

      admin = create(:admin, :power_user)
      sign_in(admin.email_authentication)

      patients = [create(:patient, full_name: "Patient one"), create(:patient, full_name: "Patient two")]
      expect(PatientDeduplication::Deduplicator).to receive(:new).and_call_original

      post :merge, params: {duplicate_patients: patients.map(&:id)}

      expect(Patient.count).to eq 1
      expect(Patient.with_discarded.count).to eq 3
    end
  end
end