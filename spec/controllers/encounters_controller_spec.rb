require 'rails_helper'

RSpec.describe Api::Current::EncountersController, type: :controller do
  let(:request_user) { create(:user) }
  let(:request_facility) { create(:facility, facility_group: request_user.facility.facility_group) }
  let(:request_patient) { create(:patient, registration_facility: request_facility) }

  let(:model) { Encounter }

  let(:build_payload) { lambda { build_encounters_payload } }
  let(:build_invalid_payload) { lambda { build_invalid_encounters_payload } }
  let(:invalid_record) { build_invalid_payload.call }

  let(:number_of_schema_errors_in_invalid_payload) { 3 }

  def build_record(_options = {})
    facility = create(:facility, facility_group: request_user.facility.facility_group)
    patient = create(:patient, registration_facility: facility)
    blood_pressure = create(:blood_pressure, facility: facility, patient: patient)
    encounter = build(:encounter, patient: patient)
    observation = build(:observation, encounter: encounter, observable: blood_pressure, user: request_user)
    encounter.observations = [observation]
    encounter.blood_pressures = [observation.observable]
    encounter
  end

  def create_record(options = {})
    facility = create(:facility, facility_group: request_user.facility.facility_group)
    patient = create(:patient, registration_facility: facility)
    blood_pressure = create(:blood_pressure, facility: facility, patient: patient)
    encounter = create(:encounter, options.merge(patient: patient))
    create(:observation, encounter: encounter, observable: blood_pressure, user: request_user)
    encounter
  end

  def create_record_list(n, options = {})
    encounters = []

    n.times.each do |_|
      encounters << create_record(options)
    end

    encounters
  end

  it_behaves_like 'a sync controller that authenticates user requests'
  it_behaves_like 'a working sync controller that short circuits disabled apis'
  it_behaves_like 'a sync controller that audits the data access'

  describe 'POST sync: send data from device to server;' do
    describe 'creates new encounters' do
      before :each do
        request.env['HTTP_X_USER_ID'] = request_user.id
        request.env['HTTP_X_FACILITY_ID'] = request_facility.id
        request.env['HTTP_AUTHORIZATION'] = "Bearer #{request_user.access_token}"
        request.env['HTTP_X_TIMEZONE_OFFSET'] = 3600
      end

      it 'creates new encounters' do
        encounters = (1..3).map do
          encounter = build_record
          build_encounters_payload(encounter)
        end

        expect {
          post(:sync_from_user, params: { encounters: encounters }, as: :json)
        }.to change { Encounter.count }.by(3)
               .and change { Observation.count }.by(3)

        expect(response).to have_http_status(200)
      end

      it 'creates new encounters with no observations' do
        empty_observations = {
          :observations => {
            :blood_pressures => []
          }
        }.with_indifferent_access

        encounter_with_no_observations = build_encounters_payload(build_record).merge(empty_observations)

        expect {
          post(:sync_from_user, params: { encounters: [encounter_with_no_observations] }, as: :json)
        }.to change { Encounter.count }.by(1)
               .and change { Observation.count }.by(0)

        expect(response).to have_http_status(200)
      end

      it 'associates registration facility with the encounter' do
        encounter = build_encounters_payload(build_record)

        expect {
          post(:sync_from_user, params: { encounters: [encounter] }, as: :json)
        }.to change { Encounter.count }.by(1)

        expect(response).to have_http_status(200)
        expect(Encounter.find(encounter[:id]).facility).to eq request_facility
      end

      it 'associates patient with the encounter' do
        encounter = build_encounters_payload(build_record)
        patient = Patient.find(encounter['patient_id'])

        expect {
          post(:sync_from_user, params: { encounters: [encounter] }, as: :json)
        }.to change { Encounter.count }.by(1)

        expect(response).to have_http_status(200)
        expect(Encounter.find(encounter[:id]).patient).to eq patient
      end
    end
  end

  describe 'GET sync: send data from server to device;' do
    it_behaves_like 'a working Current sync controller sending records'

    describe 'current facility prioritisation' do
      it "syncs request facility's records first" do
        request_2_facility = create(:facility, facility_group: request_user.facility.facility_group)

        patient_1 = create(:patient, registration_facility: request_facility)
        patient_2 = create(:patient, registration_facility: request_2_facility)

        create_list(:encounter, 2,
                    patient: patient_1,
                    facility: request_facility,
                    updated_at: 3.minutes.ago)
        create_list(:encounter, 2,
                    patient: patient_1,
                    facility: request_facility,
                    updated_at: 5.minutes.ago)
        create_list(:encounter, 2,
                    patient: patient_2,
                    facility: request_2_facility,
                    updated_at: 7.minutes.ago)
        create_list(:encounter, 2,
                    patient: patient_2,
                    facility: request_2_facility,
                    updated_at: 10.minutes.ago)

        # GET request 1
        set_authentication_headers
        get :sync_to_user, params: { limit: 4 }
        response_1_body = JSON(response.body)

        record_ids = response_1_body['encounters'].map { |r| r['id'] }
        records = model.where(id: record_ids)
        expect(records.count).to eq 4
        expect(records.map(&:facility).to_set).to eq Set[request_facility]

        # GET request 2
        get :sync_to_user, params: { limit: 4, process_token: response_1_body['process_token'] }
        response_2_body = JSON(response.body)

        record_ids = response_2_body['encounters'].map { |r| r['id'] }
        records = model.where(id: record_ids)
        expect(records.count).to eq 4
        expect(records.map(&:facility).to_set).to eq Set[request_facility, request_2_facility]
      end
    end

    describe 'syncing within a facility group' do
      let(:facility_in_same_group) { create(:facility, facility_group: request_user.facility.facility_group) }
      let(:facility_in_another_group) { create(:facility) }
      let(:patient_in_same_facility) { create(:patient, registration_facility: facility_in_same_group) }
      let(:patient_in_different_facility) { create(:patient, registration_facility: facility_in_another_group) }

      before :each do
        set_authentication_headers
        create_list(:encounter, 2,
                    patient: patient_in_different_facility,
                    facility: facility_in_another_group,
                    updated_at: 3.minutes.ago)

        create_list(:encounter, 3,
                    patient: patient_in_same_facility,
                    facility: facility_in_same_group,
                    updated_at: 5.minutes.ago)

        create_list(:encounter, 1,
                    patient: patient_in_same_facility,
                    facility: request_facility,
                    updated_at: 7.minutes.ago)
      end

      it "only sends data for facilities belonging in the sync group of user's registration facility" do
        get :sync_to_user, params: { limit: 6 }

        response_encounters = JSON(response.body)['encounters']
        response_facilities = response_encounters.map { |encounter| encounter['facility_id'] }.to_set

        expect(response_encounters.count).to eq 4
        expect(response_facilities).to match_array([request_facility.id, facility_in_same_group.id])
        expect(response_facilities).not_to include(facility_in_another_group.id)
      end
    end
  end
end
