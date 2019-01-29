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
  it_behaves_like 'a sync controller that audits the data access'
  it_behaves_like 'a working sync controller that short circuits disabled apis'

  def create_record(options = {})
    facility = FactoryBot.create(:facility, facility_group: request_user.facility.facility_group)
    FactoryBot.create(:patient, options.merge(registration_facility: facility))
  end

  def create_record_list(n, options = {})
    facility = FactoryBot.create(:facility, facility_group: request_user.facility.facility_group)
    FactoryBot.create_list(:patient, n, options.merge(registration_facility: facility))
  end

  describe 'POST sync: send data from device to server;' do
    it_behaves_like 'a working sync controller creating records'

    describe 'creates new patients' do
      before :each do
        request.env['HTTP_X_USER_ID'] = request_user.id
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

      it 'associates registration user with the patients' do
        post(:sync_from_user, params: { patients: [build_patient_payload.except('phone_numbers')] }, as: :json)
        expect(response).to have_http_status(200)
        expect(Patient.count).to eq 1
        expect(Patient.first.registration_user).to eq request_user
      end

      it 'sets the registration facility to the facility id in the header, when available' do
        request_facility = FactoryBot.create(:facility)
        request.env['HTTP_X_FACILITY_ID'] = request_facility.id
        post(:sync_from_user, params: { patients: [build_patient_payload] }, as: :json)
        expect(response).to have_http_status(200)
        expect(Patient.count).to eq 1
        expect(Patient.first.registration_facility).to eq request_facility
      end

      it 'sets the registration facility to the user registration facility when header is not available' do
        post(:sync_from_user, params: { patients: [build_patient_payload] }, as: :json)
        expect(response).to have_http_status(200)
        expect(Patient.count).to eq 1
        expect(Patient.first.registration_facility).to eq request_user.facility
      end
    end

    describe 'updates patients' do
      before :each do
        request.env['HTTP_X_USER_ID'] = request_user.id
        request.env['HTTP_AUTHORIZATION'] = "Bearer #{request_user.access_token}"
      end

      let(:existing_patients) { FactoryBot.create_list(:patient, 10) }
      let(:updated_patients_payload) { existing_patients.map { |patient| updated_patient_payload patient } }

      it 'with only updated patient attributes' do
        patients_payload = updated_patients_payload.map { |patient| patient.except('address', 'phone_numbers') }
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

        expect(PatientPhoneNumber.updated_on_server_since(sync_time).count).to eq 10
        patients_payload.each do |updated_patient|
          updated_phone_number = updated_patient['phone_numbers'].first
          db_phone_number = PatientPhoneNumber.find(updated_phone_number['id'])
          expect(db_phone_number.attributes.with_payload_keys.with_int_timestamps)
            .to eq(updated_phone_number.with_int_timestamps)
        end
      end

      it 'with all attributes and associations updated' do
        patients_payload = updated_patients_payload
        sync_time = Time.now
        post :sync_from_user, params: { patients: patients_payload }, as: :json

        patients_payload.each do |updated_patient|
          updated_patient.with_int_timestamps
          db_patient = Patient.find(updated_patient['id'])
          expect(db_patient.attributes.with_payload_keys.with_int_timestamps
                   .except('address_id')
                   .except('registration_user_id')
                   .except('registration_facility_id')
                   .except('test_data'))
            .to eq(updated_patient.except('address', 'phone_numbers'))
          expect(db_patient.address.attributes.with_payload_keys.with_int_timestamps)
            .to eq(updated_patient['address'])
        end

        expect(PatientPhoneNumber.updated_on_server_since(sync_time).count).to eq 10
        patients_payload.each do |updated_patient|
          updated_phone_number = updated_patient['phone_numbers'].first
          db_phone_number = PatientPhoneNumber.find(updated_phone_number['id'])
          expect(db_phone_number.attributes.with_payload_keys.with_int_timestamps)
            .to eq(updated_phone_number)
        end
      end
    end
  end

  describe 'GET sync: send data from server to device;' do
    it_behaves_like 'a working V1 sync controller sending records'

    describe 'syncing within a facility group' do
      let(:facility_in_same_group) { FactoryBot.create(:facility, facility_group: request_user.facility.facility_group) }
      let(:facility_in_another_group) { FactoryBot.create(:facility) }

      let(:patients_in_another_group) { FactoryBot.create_list(:patient, 5, registration_facility: facility_in_another_group, updated_at: 3.minutes.ago) }

      before :each do
        set_authentication_headers
        FactoryBot.create_list(:patient, 5, registration_facility: facility_in_same_group, updated_at: 5.minutes.ago)
        FactoryBot.create_list(:patient, 5, registration_facility: facility_in_another_group, updated_at: 3.minutes.ago)
      end

      it "only sends data for facilities belonging in the sync group of user's registration facility" do
        get :sync_to_user, params: { limit: 15 }

        response_patients = JSON(response.body)['patients']
        response_ids = response_patients.map { |patient| patient['id'] }.to_set

        expect(response_ids.count).to eq 5
        patients_in_another_group.map(&:id).each do |patient_in_another_group_id|
          expect(response_ids).not_to include(patient_in_another_group_id)
        end
      end
    end
  end
end
