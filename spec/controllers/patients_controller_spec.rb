require 'rails_helper'

RSpec.describe PatientsController, type: :controller do
  let(:counsellor) { create(:admin, :counsellor) }
  let(:facility_group) { counsellor.facility_groups.first }

  before do
    sign_in(counsellor)
  end

  describe 'GET #index' do
    render_views

    let!(:facility_1) { create(:facility, facility_group: facility_group) }
    let!(:patients_to_followup_in_facility_1) do
      patients = create_list(:patient, 50,
                             registration_facility: facility_1,
                             device_created_at: 10.days.ago)
      patients.each do |patient|
        create(:blood_pressure, patient: patient, facility: facility_1)
      end
      patients
    end

    let!(:facility_2) { create(:facility, facility_group: facility_group) }
    let!(:patients_to_followup_in_facility_2) do
      patients = create_list(:patient, 50,
                             registration_facility: facility_2,
                             device_created_at: 10.days.ago)
      patients.each do |patient|
        create(:blood_pressure, patient: patient, facility: facility_2)
      end
      patients
    end

    it 'returns a success response' do
      get :index, params: {}

      expect(response).to be_success
    end

    describe 'filtering by facility' do
      it 'displays followups for all facilities if none is selected' do
        get :index, params: { per_page: 'All' }

        expect(response.body).to include("recorded at #{facility_1.name}")
        expect(response.body).to include("recorded at #{facility_2.name}")
      end

      it 'displays followups for only the selected facility' do
        get :index, params: {
          facility_id: facility_1.id,
          per_page: 'All'
        }

        expect(response.body).to include("recorded at #{facility_1.name}")
        expect(response.body).not_to include("recorded at #{facility_2.name}")
      end
    end

    describe 'pagination' do
      it 'shows 20 records per page by default' do
        get :index, params: {}

        expect(response.body.scan(/recorded at/).length).to be(20)
      end

      it 'shows the selected number of records per page' do
        get :index, params: { per_page: 50 }

        expect(response.body.scan(/recorded at/).length).to be(50)
      end

      it 'shows all records if All is selected' do
        get :index, params: { per_page: 'All' }

        total_records = patients_to_followup_in_facility_1.size + patients_to_followup_in_facility_2.size

        expect(response.body.scan(/recorded at/).length).to be(total_records)
      end
    end
  end

  describe 'PUT #update' do
    let!(:patient) do
      facility = create(:facility, facility_group: facility_group)
      patient = create(:patient, registration_facility: facility)
      create(:blood_pressure, patient: patient, facility: facility)
      patient
    end

    it 'marks the patient as contacted' do
      put :update, params: {
        id: patient.id,
        patient: {
          call_result: 'contacted'
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
          call_result: 'moved'
        }
      }

      patient.reload

      expect(patient.could_not_contact_reason).to eq('moved')
      expect(response).to redirect_to(action: 'index')
    end

    it 'updates the status if dead' do
      put :update, params: {
        id: patient.id,
        patient: {
          call_result: 'dead'
        }
      }

      patient.reload

      expect(patient.could_not_contact_reason).to eq('dead')
      expect(patient.status).to eq('dead')
      expect(response).to redirect_to(action: 'index')
    end
  end
end
