require 'rails_helper'

RSpec.describe Api::Current::PatientsController, type: :controller do
  let(:request_user) { FactoryBot.create(:user) }
  let(:request_facility) { FactoryBot.create(:facility, facility_group: request_user.facility.facility_group) }

  let(:model) { Patient }

  let(:build_payload) { lambda { build_patient_payload } }
  let(:build_invalid_payload) { lambda { build_invalid_patient_payload } }
  let(:update_payload) { lamda { |record| updated_patient_payload record } }
  let(:invalid_record) { build_invalid_payload.call }

  let(:number_of_schema_errors_in_invalid_payload) { 2 + invalid_record['phone_numbers'].count }

  def create_record(options = {})
    facility = FactoryBot.create(:facility, facility_group: request_user.facility.facility_group)
    FactoryBot.create(:patient, options.merge(registration_facility: facility))
  end

  def create_record_list(n, options = {})
    facility = FactoryBot.create(:facility, facility_group: request_user.facility.facility_group)
    FactoryBot.create_list(:patient, n, options.merge(registration_facility: facility))
  end

  it_behaves_like 'a sync controller that authenticates user requests'
  it_behaves_like 'a sync controller that audits the data access'
  it_behaves_like 'a working sync controller that short circuits disabled apis'

  describe 'POST sync: send data from device to server;' do
    it_behaves_like 'a working sync controller creating records'

    describe 'creates new patients' do
      before :each do
        request.env['HTTP_X_USER_ID'] = request_user.id
        request.env['HTTP_X_FACILITY_ID'] = request_facility.id
        request.env['HTTP_AUTHORIZATION'] = "Bearer #{request_user.access_token}"
      end

      it 'creates new patients' do
        patients = (1..3).map { build_patient_payload }
        post(:sync_from_user, params: { patients: patients }, as: :json)
        expect(Patient.count).to eq 3
        expect(Address.count).to eq 3
        expect(PatientPhoneNumber.count).to eq(patients.sum { |patient| patient['phone_numbers'].count })
        expect(response).to have_http_status(200)
      end

      it 'sets the recorded_at sent in the params' do
        time = Time.now
        patient = FactoryBot.build(:patient, recorded_at: time)
        patient_payload = build_patient_payload(patient)
        post(:sync_from_user, params: { patients: [patient_payload] }, as: :json)

        patient_in_db = Patient.find(patient.id)
        expect(patient_in_db.recorded_at.to_i).to eq(time.to_i)
      end

      context 'recorded_at is not sent' do
        it 'defaults recorded_at to device_created_at' do
          patient = FactoryBot.build(:patient)
          patient_payload = build_patient_payload(patient).except('recorded_at')
          post(:sync_from_user, params: { patients: [patient_payload] }, as: :json)

          patient_in_db = Patient.find(patient.id)
          expect(patient_in_db.recorded_at.to_i).to eq(patient_in_db.device_created_at.to_i)
        end

        it "sets recorded_at to the earliest bp's recorded_at in case patient is synced later" do
          patient = FactoryBot.build(:patient)
          blood_pressure_recorded_at = 1.month.ago
          FactoryBot.create(:blood_pressure,
                            patient_id: patient.id,
                            recorded_at: blood_pressure_recorded_at)

          patient_payload = build_patient_payload(patient).except('recorded_at')
          post :sync_from_user, params: { patients: [patient_payload] }, as: :json

          patient_in_db = Patient.find(patient.id)
          expect(patient_in_db.recorded_at.to_i).to eq(blood_pressure_recorded_at.to_i)
        end
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

      it 'creates new patients without business identifiers' do
        post(:sync_from_user, params: { patients: [build_patient_payload.except('business_identifiers')] }, as: :json)
        expect(Patient.count).to eq 1
        expect(PatientBusinessIdentifier.count).to eq 0
        expect(response).to have_http_status(200)
      end

      it 'associates registration user with the patients' do
        post(:sync_from_user, params: { patients: [build_patient_payload.except('phone_numbers')] }, as: :json)
        expect(response).to have_http_status(200)
        expect(Patient.count).to eq 1
        expect(Patient.first.registration_user).to eq request_user
      end

      it 'associates registration facility with the patients' do
        post(:sync_from_user, params: { patients: [build_patient_payload.except('phone_numbers')] }, as: :json)
        expect(response).to have_http_status(200)
        expect(Patient.count).to eq 1
        expect(Patient.first.registration_facility).to eq request_facility
      end
    end

    describe 'updates patients' do
      before :each do
        request.env['HTTP_X_USER_ID'] = request_user.id
        request.env['HTTP_X_FACILITY_ID'] = request_facility.id
        request.env['HTTP_AUTHORIZATION'] = "Bearer #{request_user.access_token}"
      end

      let(:existing_patients) { FactoryBot.create_list(:patient, 3) }
      let(:updated_patients_payload) { existing_patients.map { |patient| updated_patient_payload patient } }

      it 'with only updated patient attributes' do
        patients_payload = updated_patients_payload.map do |patient|
          patient.except('address', 'phone_numbers', 'business_identifiers')
        end
        post :sync_from_user, params: { patients: patients_payload }, as: :json

        patients_payload.each do |updated_patient|
          db_patient = Patient.find(updated_patient['id'])
          expect(db_patient.attributes.with_payload_keys.with_int_timestamps
                   .except('address_id')
                   .except('registration_user_id')
                   .except('registration_facility_id')
                   .except('test_data'))
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
        sync_time = Time.now
        post :sync_from_user, params: { patients: patients_payload }, as: :json

        expect(PatientPhoneNumber.updated_on_server_since(sync_time).count).to eq 3
        patients_payload.each do |updated_patient|
          updated_phone_number = updated_patient['phone_numbers'].first
          db_phone_number = PatientPhoneNumber.find(updated_phone_number['id'])
          expect(db_phone_number.attributes.with_payload_keys.with_int_timestamps)
            .to eq(updated_phone_number.with_int_timestamps)
        end
      end

      describe 'with all attributes and associations updated' do
        let!(:patients_payload) { updated_patients_payload }
        let!(:sync_time) { Time.now }

        before do
          post :sync_from_user, params: { patients: patients_payload }, as: :json
        end

        it 'updates non-nested fields' do
          patients_payload.each do |updated_patient|
            updated_patient.with_int_timestamps
            db_patient = Patient.find(updated_patient['id'])
            expect(db_patient.attributes.with_payload_keys.with_int_timestamps
                     .except('address_id')
                     .except('registration_user_id')
                     .except('registration_facility_id')
                     .except('test_data'))
              .to eq(updated_patient.except('address', 'phone_numbers', 'business_identifiers'))
          end
        end

        it 'updates address' do
          patients_payload.each do |updated_patient|
            updated_patient.with_int_timestamps
            db_patient = Patient.find(updated_patient['id'])

            expect(db_patient.address.attributes.with_payload_keys.with_int_timestamps)
              .to eq(updated_patient['address'])
          end
        end

        it 'updates phone numbers' do
          expect(PatientPhoneNumber.updated_on_server_since(sync_time).count).to eq 3

          patients_payload.each do |updated_patient|
            updated_patient.with_int_timestamps
            updated_phone_number = updated_patient['phone_numbers'].first
            db_phone_number = PatientPhoneNumber.find(updated_phone_number['id'])

            expect(db_phone_number.attributes.with_payload_keys.with_int_timestamps)
              .to eq(updated_phone_number)
          end
        end

        it 'updates business identifiers' do
          expect(PatientBusinessIdentifier.updated_on_server_since(sync_time).count).to eq 3

          patients_payload.each do |updated_patient|
            updated_patient.with_int_timestamps
            updated_business_identifier = updated_patient['business_identifiers'].first
            updated_business_identifier_metadata = JSON.parse(updated_business_identifier[:metadata]) if updated_business_identifier[:metadata].present?
            db_business_identifier = PatientBusinessIdentifier.find(updated_business_identifier['id'])

            expect(db_business_identifier.attributes.with_payload_keys.with_int_timestamps)
              .to eq(updated_business_identifier.merge('metadata' => updated_business_identifier_metadata))
          end
        end
      end

      it 'does not change registration user or facility' do
        current_user = FactoryBot.create(:user)
        current_facility = FactoryBot.create(:facility, facility_group: current_user.facility.facility_group)
        request.env['HTTP_X_USER_ID'] = current_user.id
        request.env['HTTP_X_FACILITY_ID'] = current_facility.id
        request.env['HTTP_AUTHORIZATION'] = "Bearer #{current_user.access_token}"

        patients_payload = updated_patients_payload

        previous_registration_user_id = Patient.first.registration_user_id
        previous_registration_facility_id = Patient.first.registration_facility_id

        post :sync_from_user, params: { patients: patients_payload }, as: :json

        expect(response).to have_http_status(200)
        patient = Patient.first
        expect(patient.registration_user.id).to eq previous_registration_user_id
        expect(patient.registration_facility.id).to eq previous_registration_facility_id
        expect(patient.registration_user.id).to_not eq current_user.id
        expect(patient.registration_facility.id).to_not eq current_facility.id
      end
    end
  end

  describe 'GET sync: send data from server to device;' do
    it_behaves_like 'a working Current sync controller sending records'

    describe 'current facility prioritisation' do
      it "syncs request facility's records first" do
        request_2_facility = FactoryBot.create(:facility, facility_group: request_user.facility.facility_group)
        FactoryBot.create_list(:patient, 2, registration_facility: request_2_facility, updated_at: 3.minutes.ago)
        FactoryBot.create_list(:patient, 2, registration_facility: request_2_facility, updated_at: 5.minutes.ago)
        FactoryBot.create_list(:patient, 2, registration_facility: request_facility, updated_at: 7.minutes.ago)
        FactoryBot.create_list(:patient, 2, registration_facility: request_facility, updated_at: 10.minutes.ago)

        # GET request 1
        set_authentication_headers
        get :sync_to_user, params: { limit: 4 }
        response_1_body = JSON(response.body)

        record_ids = response_1_body['patients'].map { |r| r['id'] }
        records = model.where(id: record_ids)
        expect(records.count).to eq 4
        expect(records.map(&:registration_facility).to_set).to eq Set[request_facility]

        # GET request 2
        get :sync_to_user, params: { limit: 4, process_token: response_1_body['process_token'] }
        response_2_body = JSON(response.body)

        record_ids = response_2_body['patients'].map { |r| r['id'] }
        records = model.where(id: record_ids)
        expect(records.count).to eq 4
        expect(records.map(&:registration_facility).to_set).to eq Set[request_facility, request_2_facility]
      end
    end

    describe 'syncing within a facility group' do
      let(:facility_in_same_group) { FactoryBot.create(:facility, facility_group: request_user.facility.facility_group) }
      let(:facility_in_another_group) { FactoryBot.create(:facility) }

      let(:patients_in_another_group) { FactoryBot.create_list(:patient, 2, registration_facility: facility_in_another_group, updated_at: 3.minutes.ago) }

      before :each do
        set_authentication_headers
        FactoryBot.create_list(:patient, 2, registration_facility: request_facility, updated_at: 7.minutes.ago)
        FactoryBot.create_list(:patient, 2, registration_facility: facility_in_same_group, updated_at: 5.minutes.ago)
      end

      it "only sends data for facilities belonging in the sync group of user's registration facility" do
        get :sync_to_user, params: { limit: 15 }

        response_patients = JSON(response.body)['patients']
        response_ids = response_patients.map { |patient| patient['id'] }.to_set

        expect(response_ids.count).to eq 4
        patients_in_another_group.map(&:id).each do |patient_in_another_group_id|
          expect(response_ids).not_to include(patient_in_another_group_id)
        end
      end
    end
  end
end
