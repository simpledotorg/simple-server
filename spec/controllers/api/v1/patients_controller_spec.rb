require 'rails_helper'

RSpec.describe Api::V1::PatientsController, type: :controller do
  describe 'POST sync: send data from device to server;' do

    describe 'creates new patients' do

      it 'returns 400 when there are no patients in the request' do
        post(:sync_from_user, params: { patients: [] })
        expect(response.status).to eq 400
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

      it 'returns errors for invalid records' do
        payload = build_invalid_patient_payload
        post(:sync_from_user, params: { patients: [payload] }, as: :json)

        patient_errors = JSON(response.body)['errors'].first
        expect(patient_errors).to be_present
        expect(patient_errors['schema']).to be_present
        expect(patient_errors['id']).to be_present
        expect(patient_errors['schema'].count).to eq 2 + payload['phone_numbers'].count
      end

      it 'returns errors for some invalid records, and accepts others' do
        invalid_patients_payload = (1..5).map { build_invalid_patient_payload }
        valid_patients_payload   = (1..5).map { build_patient_payload }
        post(:sync_from_user, params: { patients: invalid_patients_payload + valid_patients_payload }, as: :json)

        patient_errors = JSON(response.body)['errors']
        expect(patient_errors.count).to eq 5
        expect(patient_errors.map { |error| error['id'] })
          .to match_array(invalid_patients_payload.map { |patient| patient['id'] })

        expect(Patient.count).to eq 5
        expect(Patient.pluck(:id))
          .to match_array(valid_patients_payload.map { |patient| patient['id'] })
      end
    end

    describe 'updates patients' do

      let(:existing_patients) { FactoryBot.create_list(:patient, 10) }
      let(:updated_patients_payload) { existing_patients.map { |patient| updated_patient_payload patient } }


      it 'with only updated patient attributes' do
        patients_payload = updated_patients_payload.map { |patient| patient.except('address', 'phone_numbers') }
        post :sync_from_user, params: { patients: patients_payload }, as: :json

        patients_payload.each do |updated_patient|
          db_patient = Patient.find(updated_patient['id'])
          expect(db_patient.attributes.with_int_timestamps.except('address_id', 'updated_on_server_at'))
            .to eq(updated_patient.with_int_timestamps)
        end
      end

      it 'with only updated address' do
        patients_payload = updated_patients_payload.map { |patient| patient.except('phone_numbers') }
        post :sync_from_user, params: { patients: patients_payload }, as: :json

        patients_payload.each do |updated_patient|
          db_patient = Patient.find(updated_patient['id'])
          expect(db_patient.address.attributes.with_int_timestamps.except('updated_on_server_at'))
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
          expect(db_phone_number.attributes.with_int_timestamps.except('updated_on_server_at'))
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
          expect(db_patient.attributes.with_int_timestamps.except('address_id', 'updated_on_server_at'))
            .to eq(updated_patient.except('address', 'phone_numbers'))
          expect(db_patient.address.attributes.with_int_timestamps.except('updated_on_server_at'))
            .to eq(updated_patient['address'])
        end

        expect(PatientPhoneNumber.updated_on_server_since(sync_time).count).to eq 10
        patients_payload.each do |updated_patient|
          updated_phone_number = updated_patient['phone_numbers'].first
          db_phone_number      = PatientPhoneNumber.find(updated_phone_number['id'])
          expect(db_phone_number.attributes.with_int_timestamps.except('updated_on_server_at'))
            .to eq(updated_phone_number)
        end
      end
    end
  end

  describe 'GET sync: send data from server to device;' do
    before :each do
      Timecop.travel(15.minutes.ago) do
        FactoryBot.create_list(:patient, 10)
      end
    end

    it 'Returns records from the beginning of time, when processed_since is not set' do
      get :sync_to_user

      response_body = JSON(response.body)
      expect(response_body['patients'].count).to eq Patient.count
      expect(response_body['patients'].map { |patient| patient['id'] }.to_set)
        .to eq(Patient.all.pluck(:id).to_set)
    end

    it 'Returns new patients added since last sync' do
      expected_patients = FactoryBot.create_list(:patient, 5, updated_on_server_at: 5.minutes.ago)
      get :sync_to_user, params: { processed_since: 10.minutes.ago }

      response_body = JSON(response.body)
      expect(response_body['patients'].count).to eq 5

      expect(response_body['patients'].map { |patient| patient['id'] }.to_set)
        .to eq(expected_patients.map(&:id).to_set)

      expect(response_body['processed_since'].to_time.to_i)
        .to eq(expected_patients.map(&:updated_on_server_at).max.to_i)
    end

    describe 'nothing to sync' do
      it 'Returns an empty list when there is nothing to sync' do
        sync_time = 10.minutes.ago
        get :sync_to_user, params: { processed_since: sync_time }
        response_body = JSON(response.body)
        expect(response_body['patients'].count).to eq 0
        expect(response_body['processed_since'].to_time.to_i).to eq sync_time.to_i
      end

    end

    describe 'batching' do
      it 'Returns the number of records requested with limit' do
        get :sync_to_user, params: { processed_since: 20.minutes.ago,
                                     limit:           2 }
        response_body = JSON(response.body)
        expect(response_body['patients'].count).to eq 2
      end

      it 'Returns all the records on server over multiple small batches' do
        get :sync_to_user, params: { processed_since: 20.minutes.ago,
                                     limit:           7 }
        response_1 = JSON(response.body)

        get :sync_to_user, params: { processed_since: response_1['processed_since'],
                                     limit:           7 }

        response_2 = JSON(response.body)

        received_patients = response_1['patients'].concat(response_2['patients']).to_set
        expect(received_patients.count).to eq Patient.count

        expect(received_patients.to_set)
          .to eq JSON(Patient.all.map(&:nested_hash).to_json).to_set
      end
    end
  end
end
