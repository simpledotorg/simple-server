require 'rails_helper'

RSpec.describe Api::V1::PatientsController, type: :controller do
  let(:request_user) { FactoryBot.create(:user) }

  let(:model) { Patient }

  let(:build_payload) { lambda { build_patient_payload } }
  let(:build_invalid_payload) { lambda { build_invalid_patient_payload } }
  let(:update_payload) { lamda { |record| updated_patient_payload record } }
  let(:invalid_record) { build_invalid_payload.call }

  let(:number_of_schema_errors_in_invalid_payload) { 2 + invalid_record['phone_numbers'].count }

  it_behaves_like 'a sync controller that authenticates user requests'
  describe 'POST sync: send data from device to server;' do
    it_behaves_like 'a working sync controller creating records'

    describe 'creates new patients' do
      before :each do
        request.env['X_USER_ID'] = request_user.id
        request.env['HTTP_AUTHORIZATION'] = "Bearer #{request_user.access_token}"
      end

      it 'creates new patients' do
        patients = (1..10).map { build_patient_payload }
        post(:sync_from_user, params: { patients: patients }, as: :json)
        expect(Patient.count).to eq 10
        expect(Address.count).to eq 10
        expect(PatientPhoneNumber.count).to eq(patients.sum { |patient| patient['phone_numbers'].count })
        expect(response).to have_http_status(200)
      end
      it 'creates new patients without address' do
        post(:sync_from_user, params: { patients: [build_patient_payload.except('address')] }, as: :json)
        expect(Patient.count).to eq 1
        expect(Address.count).to eq 0
        expect(response).to have_http_status(200)
      end

      it 'creates new patients without phone numbers' do
        post(:sync_from_user, params: { patients: [build_patient_payload.except('phone_numbers')] }, as: :json)
        expect(Patient.count).to eq 1
        expect(PatientPhoneNumber.count).to eq 0
        expect(response).to have_http_status(200)
      end
    end

    describe 'updates patients' do
      before :each do
        request.env['X_USER_ID'] = request_user.id
        request.env['HTTP_AUTHORIZATION'] = "Bearer #{request_user.access_token}"
      end

      let(:existing_patients) { FactoryBot.create_list(:patient, 10) }
      let(:updated_patients_payload) { existing_patients.map { |patient| updated_patient_payload patient } }

      it 'with only updated patient attributes' do
        patients_payload = updated_patients_payload.map { |patient| patient.except('address', 'phone_numbers') }
        post :sync_from_user, params: { patients: patients_payload }, as: :json

        patients_payload.each do |updated_patient|
          db_patient = Patient.find(updated_patient['id'])
          expect(db_patient.attributes.with_payload_keys.with_int_timestamps.except('address_id'))
            .to eq(updated_patient.with_int_timestamps)
        end
      end

      it 'with only updated address' do
        patients_payload = updated_patients_payload.map { |patient| patient.except('phone_numbers') }
        post :sync_from_user, params: { patients: patients_payload }, as: :json

        patients_payload.each do |updated_patient|
          db_patient = Patient.find(updated_patient['id'])
          expect(db_patient.address.attributes.with_payload_keys.with_int_timestamps)
            .to eq(updated_patient['address'].with_int_timestamps)
        end
      end

      it 'with only updated phone numbers' do
        patients_payload = updated_patients_payload.map { |patient| patient.except('address') }
        sync_time        = Time.now
        post :sync_from_user, params: { patients: patients_payload }, as: :json

        expect(PatientPhoneNumber.updated_on_server_since(sync_time).count).to eq 10
        patients_payload.each do |updated_patient|
          updated_phone_number = updated_patient['phone_numbers'].first
          db_phone_number      = PatientPhoneNumber.find(updated_phone_number['id'])
          expect(db_phone_number.attributes.with_payload_keys.with_int_timestamps)
            .to eq(updated_phone_number.with_int_timestamps)
        end
      end

      it 'with all attributes and associations updated' do
        patients_payload = updated_patients_payload
        sync_time        = Time.now
        post :sync_from_user, params: { patients: patients_payload }, as: :json

        patients_payload.each do |updated_patient|
          updated_patient.with_int_timestamps
          db_patient = Patient.find(updated_patient['id'])
          expect(db_patient.attributes.with_payload_keys.with_int_timestamps.except('address_id'))
            .to eq(updated_patient.except('address', 'phone_numbers'))
          expect(db_patient.address.attributes.with_payload_keys.with_int_timestamps)
            .to eq(updated_patient['address'])
        end

        expect(PatientPhoneNumber.updated_on_server_since(sync_time).count).to eq 10
        patients_payload.each do |updated_patient|
          updated_phone_number = updated_patient['phone_numbers'].first
          db_phone_number      = PatientPhoneNumber.find(updated_phone_number['id'])
          expect(db_phone_number.attributes.with_payload_keys.with_int_timestamps)
            .to eq(updated_phone_number)
        end
      end
    end
  end

  describe 'GET sync: send data from server to device;' do
    it_behaves_like 'a working sync controller sending records'
  end
end
