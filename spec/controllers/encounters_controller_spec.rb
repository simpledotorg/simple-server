require 'rails_helper'

RSpec.describe Api::Current::EncountersController, type: :controller do
  let(:request_user) { FactoryBot.create(:user) }
  let(:request_facility) { FactoryBot.create(:facility, facility_group: request_user.facility.facility_group) }
  let(:request_patient) { FactoryBot.create(:patient, registration_facility: request_facility) }

  let(:model) { Encounter }

  let(:build_payload) { lambda { build_encounters_payload } }
  let(:build_invalid_payload) { lambda { build_invalid_encounters_payload } }
  let(:invalid_record) { build_invalid_payload.call }

  let(:number_of_schema_errors_in_invalid_payload) { 3 }

  def create_record(_options = {})
    facility = FactoryBot.build(:facility, facility_group: request_user.facility.facility_group)
    patient = FactoryBot.create(:patient, registration_facility: facility)
    blood_pressure = FactoryBot.build(:blood_pressure, facility: facility, patient: patient)
    encounter = FactoryBot.build(:encounter, patient: patient)
    observation = FactoryBot.build(:observation, encounter: encounter, observable: blood_pressure)
    encounter.observations = [observation]
    encounter.blood_pressures = [observation.observable]
    encounter
  end

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
          encounter = create_record
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

        encounter_with_empty_observations = build_encounters_payload(create_record).merge(empty_observations)

        expect {
          post(:sync_from_user, params: { encounters: [encounter_with_empty_observations] }, as: :json)
        }.to change { Encounter.count }.by(1)
               .and change { Observation.count }.by(0)

        expect(response).to have_http_status(200)
      end

      it 'associates registration facility with the encounter' do
        encounter = build_encounters_payload(create_record)

        expect {
          post(:sync_from_user, params: { encounters: [encounter] }, as: :json)
        }.to change { Encounter.count }.by(1)

        expect(response).to have_http_status(200)
        expect(Encounter.find(encounter[:id]).facility).to eq request_facility
      end

      it 'associates patient with the encounter' do
        encounter = build_encounters_payload(create_record)
        patient = Patient.find(encounter['patient_id'])

        expect {
          post(:sync_from_user, params: { encounters: [encounter] }, as: :json)
        }.to change { Encounter.count }.by(1)

        expect(response).to have_http_status(200)
        expect(Encounter.find(encounter[:id]).patient).to eq patient
      end
    end
  end
end
