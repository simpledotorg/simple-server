require 'rails_helper'

RSpec.describe PatientsController, type: :controller do
  let(:counsellor) { create(:admin, :counsellor) }
  let(:facility_group) { counsellor.facility_groups.first }
  let(:facility) { create(:facility, facility_group: facility_group) }

  let!(:patient) do
    patient = create(:patient, registration_facility: facility)
    create(:blood_pressure, patient: patient, facility: facility)
    patient
  end

  before do
    sign_in(counsellor)
  end

  describe 'GET #index' do
    it 'returns a success response' do
      get :index, params: {}
      expect(response).to be_success
    end
  end

  describe 'GET #edit' do
    it 'returns a success response' do
      get :edit, params: { id: patient.id }
      expect(response).to be_success
    end
  end

  describe 'GET #cancel' do
    it 'returns a success response' do
      get :cancel, params: { patient_id: patient.id }
      expect(response).to be_success
    end
  end

  describe 'PUT #update' do
    it 'marks the patient as contacted' do
      put :update, params: {
        id: patient.id,
        patient: {
          contacted_by_counsellor: true
        }
      }

      patient.reload

      expect(patient.contacted_by_counsellor).to be(true)
      expect(response).to redirect_to(action: 'index')
    end

    it 'sets reason why the patient could not be contacted' do
      put :update, params: {
        id: patient.id,
        patient: {
          could_not_contact_reason: 'dead'
        }
      }

      patient.reload

      expect(patient.could_not_contact_reason).to eq('dead')
      expect(response).to redirect_to(action: 'index')
    end
  end
end
