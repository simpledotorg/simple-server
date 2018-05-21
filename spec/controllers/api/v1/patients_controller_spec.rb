require 'rails_helper'

def patient_attrs(patient_hash)
  patient_hash.except('address_id', 'address', 'phone_numbers', 'updated_on_server_at')
end

RSpec.describe Api::V1::PatientsController, type: :controller do
  describe 'POST sync: send data from device to server;' do

    describe 'creates new patients' do
      it 'creates new patients' do
        patients = (1..10).map { build_patient_payload }
        post(:sync_from_user, params: { patients: patients })
        expect(Patient.count).to eq 10
        expect(Address.count).to eq 10
        expect(PhoneNumber.count).to eq(patients.sum { |patient| patient['phone_numbers'].count })
        expect(response).to have_http_status(200)
      end

      it 'creates new patients without address' do
        post(:sync_from_user, params: { patients: [build_patient_payload.except('address')] })
        expect(Patient.count).to eq 1
        expect(Address.count).to eq 0
        expect(response).to have_http_status(200)
      end

      it 'creates new patients without phone numbers' do
        post(:sync_from_user, params: { patients: [build_patient_payload.except('phone_numbers')] })
        expect(Patient.count).to eq 1
        expect(PhoneNumber.count).to eq 0
        expect(response).to have_http_status(200)
      end

      it 'returns errors for invalid records' do
        post(:sync_from_user, params: { patients: [build_invalid_patient_payload] })

        patient_errors = JSON(response.body)['errors'].first
        expect(patient_errors).to be_present
        expect(patient_errors['created_at']).to be_present
        expect(patient_errors['id']).to be_present
        expect(patient_errors['address']['created_at']).to be_present
        expect(patient_errors['address']['id']).to be_present
        expect(patient_errors['phone_numbers'].map { |phno| phno['id'] }).to all(be_present)
        expect(patient_errors['phone_numbers'].map { |phno| phno['created_at'] }).to all(be_present)
      end
    end

    describe 'updates patients' do

      let(:existing_patients) { FactoryBot.create_list(:patient, 10) }
      let(:updated_patients_payload) do
        existing_patients.map do |existing_patient|
          phone_number = existing_patient.phone_numbers.sample || FactoryBot.build(:phone_number)
          update_time  = 10.days.from_now
          build_patient_payload(existing_patient).deep_merge(
            'full_name'     => Faker::Name.name,
            'updated_at'    => update_time,
            'address'       => { 'updated_at'     => update_time,
                                 'street_address' => Faker::Address.street_address },
            'phone_numbers' => [phone_number.attributes.merge(
              'updated_at' => update_time,
              'number'     => Faker::PhoneNumber.phone_number).except('updated_on_server_at')]
          )
        end
      end

      it 'with only updated patient attributes' do
        patients_payload = updated_patients_payload.map { |patient| patient.except('address', 'phone_numbers') }
        post :sync_from_user, params: { patients: patients_payload }

        patients_payload.each do |updated_patient|
          db_patient = Patient.find(updated_patient['id'])
          expect(db_patient.attributes.with_int_timestamps.except('address_id', 'updated_on_server_at'))
            .to eq(updated_patient.with_int_timestamps)
        end
      end

      it 'with only updated address' do
        patients_payload = updated_patients_payload.map { |patient| patient.except('phone_numbers') }
        post :sync_from_user, params: { patients: patients_payload }

        patients_payload.each do |updated_patient|
          db_patient = Patient.find(updated_patient['id'])
          expect(db_patient.address.attributes.with_int_timestamps.except('updated_on_server_at'))
            .to eq(updated_patient['address'].with_int_timestamps)
        end
      end

      it 'with only updated phone numbers' do
        patients_payload = updated_patients_payload.map { |patient| patient.except('address') }
        sync_time        = Time.now
        post :sync_from_user, params: { patients: patients_payload }

        expect(PhoneNumber.updated_on_server_since(sync_time).count).to eq 10
        patients_payload.each do |updated_patient|
          updated_phone_number = updated_patient['phone_numbers'].first
          db_phone_number      = PhoneNumber.find(updated_phone_number['id'])
          expect(db_phone_number.attributes.with_int_timestamps.except('updated_on_server_at'))
            .to eq(updated_phone_number.with_int_timestamps)
        end
      end

      it 'with all attributes and associations updated' do
        patients_payload = updated_patients_payload
        sync_time        = Time.now
        post :sync_from_user, params: { patients: patients_payload }

        patients_payload.each do |updated_patient|
          db_patient = Patient.find(updated_patient['id'])
          expect(db_patient.attributes.with_int_timestamps.except('address_id', 'updated_on_server_at'))
            .to eq(updated_patient.with_int_timestamps.except('address', 'phone_numbers'))
          expect(db_patient.address.attributes.with_int_timestamps.except('updated_on_server_at'))
            .to eq(updated_patient['address'].with_int_timestamps)

          expect(PhoneNumber.updated_on_server_since(sync_time).count).to eq 10
          patients_payload.each do |updated_patient|
            updated_phone_number = updated_patient['phone_numbers'].first
            db_phone_number      = PhoneNumber.find(updated_phone_number['id'])
            expect(db_phone_number.attributes.with_int_timestamps.except('updated_on_server_at'))
              .to eq(updated_phone_number.with_int_timestamps)
          end
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

    describe 'first time sync' do
      it 'Returns records from the beginning of time, when first_time param is true' do
        get :sync_to_user, params: { first_time: true }

        response_body = JSON(response.body)
        expect(response_body['patients'].count).to eq Patient.count
        expect(response_body['patients'].map { |patient| patient['id'] }.to_set)
          .to eq(Patient.all.pluck(:id).to_set)
      end

      it 'complains when first_time is not true, and latest_record_timestamp is not set' do
        get :sync_to_user, params: { first_time: false }
        expect(response.status).to eq 400
      end
    end

    it 'Returns new patients added since last sync' do
      expected_patients = FactoryBot.create_list(:patient, 5, updated_on_server_at: 5.minutes.ago)
      get :sync_to_user, params: { latest_record_timestamp: 10.minutes.ago }

      response_body = JSON(response.body)
      expect(response_body['patients'].count).to eq 5

      expect(response_body['patients'].map { |patient| patient['id'] }.to_set)
        .to eq(expected_patients.map(&:id).to_set)

      expect(response_body['latest_record_timestamp'].to_time.to_i)
        .to eq(expected_patients.map(&:updated_on_server_at).max.to_i)
    end

    describe 'nothing to sync' do
      it 'Returns an empty list when there is nothing to sync' do
        sync_time = 10.minutes.ago
        get :sync_to_user, params: { latest_record_timestamp: sync_time}
        response_body = JSON(response.body)
        expect(response_body['patients'].count).to eq 0
        expect(response_body['latest_record_timestamp'].to_time.to_i).to eq sync_time.to_i
      end

    end
    describe 'batching' do
      it 'Returns the number of records requested with number_of_records' do
        get :sync_to_user, params: { latest_record_timestamp: 20.minutes.ago,
                                     number_of_records:       2 }
        response_body = JSON(response.body)
        expect(response_body['patients'].count).to eq 2
      end

      it 'Returns all the records on server over multiple small batches' do
        get :sync_to_user, params: { latest_record_timestamp: 20.minutes.ago,
                                     number_of_records:       7 }
        response_1 = JSON(response.body)

        get :sync_to_user, params: { latest_record_timestamp: response_1['latest_record_timestamp'],
                                     number_of_records:       7 }
        response_2 = JSON(response.body)

        received_patients = response_1['patients'].concat(response_2['patients']).to_set
        expect(received_patients.count).to eq Patient.count

        expect(received_patients.to_set)
          .to eq JSON(Patient.all.map(&:nested_hash).to_json).to_set
      end
    end
  end
end
