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

  def create_record(options = {})
    facility = FactoryBot.create(:facility, facility_group: request_user.facility.facility_group)
    patient = FactoryBot.create(:patient, registration_facility: facility)
    blood_pressure = FactoryBot.create(:blood_pressure, facility: facility,
                                       patient: patient)

    encounter = FactoryBot.create(:encounter, patient_id: patient.id,
                                  facility_id: facility.id)

    FactoryBot.create(:observation, encounter_id: encounter.id,
                      observable_type: 'BloodPressure',
                      observable_id: blood_pressure.id)
    encounter
  end

  describe 'POST sync: send data from device to server;' do
    describe 'creates new encounters' do
      before :each do
        request.env['HTTP_X_USER_ID'] = request_user.id
        request.env['HTTP_X_FACILITY_ID'] = request_facility.id
        request.env['HTTP_AUTHORIZATION'] = "Bearer #{request_user.access_token}"
      end

      it 'creates new encounters' do
        encounters = (1..3).map do
          encounter = create_record
          build_encounters_payload(encounter)
        end

        post(:sync_from_user, params: { encounters: encounters }, as: :json)

        expect(Encounter.count).to eq 3
        expect(Observation.count).to eq 3
        expect(response).to have_http_status(200)
      end

      xit 'creates new encounters with no observations' do
        encounter_with_empty_observations = build_encounters_payload(create_record).merge('observations' => {
          'blood_pressures' => [],
          'prescription_drugs' => []
        })

        post(:sync_from_user, params: { encounters: [encounter_with_empty_observations] }, as: :json)

        expect(Encounter.count).to eq 1
        expect(Observation.count).to eq 0
        expect(response).to have_http_status(200)
      end

      it ' associates registration facility with the encounter ' do
        encounter = build_encounters_payload(create_record)
        facility = Facility.find(encounter['facility_id'])

        post(:sync_from_user, params: { encounters: [encounter] }, as: :json)

        expect(response).to have_http_status(200)
        expect(Encounter.count).to eq 1
        expect(Encounter.first.facility).to eq facility
      end

      it ' associates patient with the encounter' do
        encounter = build_encounters_payload(create_record)
        patient = Patient.find(encounter['patient_id'])

        post(:sync_from_user, params: { encounters: [encounter] }, as: :json)

        expect(response).to have_http_status(200)
        expect(Encounter.count).to eq 1
        expect(Encounter.first.patient).to eq patient
      end
    end
  end
end
