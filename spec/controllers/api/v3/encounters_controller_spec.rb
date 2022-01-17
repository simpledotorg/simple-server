require "rails_helper"

RSpec.describe Api::V3::EncountersController, type: :controller do
  let(:request_user) { create(:user) }
  let(:request_facility_group) { request_user.facility.facility_group }
  let(:request_facility) { create(:facility, facility_group: request_facility_group) }
  let(:request_patient) { create(:patient, registration_facility: request_facility) }
  let(:model) { Encounter }
  let(:build_payload) { -> { build_encounters_payload } }
  let(:build_invalid_payload) { -> { build_invalid_encounters_payload } }
  let(:invalid_record) { build_invalid_payload.call }
  let(:number_of_schema_errors_in_invalid_payload) { 3 }

  def build_record(options = {})
    build(:encounter, :with_observables, {patient: request_patient, facility: request_facility}.merge(options))
  end

  def create_record(options = {})
    create(:encounter, :with_observables, {patient: request_patient, facility: request_facility}.merge(options))
  end

  def create_record_list(n, options = {})
    encounters = []
    facility = options[:facility] || create(:facility, facility_group: request_facility.facility_group)
    patient = create(:patient, registration_facility: facility)

    n.times.each do |_|
      encounters << create_record({facility: facility, patient: patient}.merge(options))
    end

    encounters
  end

  around do |example|
    Flipper.enable(:sync_encounters)
    example.run
    Flipper.disable(:sync_encounters)
  end

  it_behaves_like "a sync controller that authenticates user requests"
  it_behaves_like "a sync controller that audits the data access"

  describe "POST sync: send data from device to server;" do
    describe "creates new encounters" do
      before :each do
        request.env["HTTP_X_USER_ID"] = request_user.id
        request.env["HTTP_X_FACILITY_ID"] = request_facility.id
        request.env["HTTP_AUTHORIZATION"] = "Bearer #{request_user.access_token}"
        request.env["HTTP_X_TIMEZONE_OFFSET"] = 3600
      end

      it "creates new encounters" do
        encounters = (1..3).map {
          encounter = build_record
          build_encounters_payload(encounter)
        }

        expect {
          post(:sync_from_user, params: {encounters: encounters}, as: :json)
        }.to change { Encounter.count }.by(3)

        expect(response).to have_http_status(200)
      end

      it "creates new encounters with no observations" do
        empty_observations = {
          observations: {
            blood_pressures: []
          }
        }.with_indifferent_access

        encounter_with_no_observations = build_encounters_payload(build_record).merge(empty_observations)

        expect {
          post(:sync_from_user, params: {encounters: [encounter_with_no_observations]}, as: :json)
        }.to change { Encounter.count }.by(1)
          .and change { Observation.count }.by(0)

        expect(response).to have_http_status(200)
      end

      it "associates registration facility with the encounter" do
        encounter = build_encounters_payload(build_record)

        expect {
          post(:sync_from_user, params: {encounters: [encounter]}, as: :json)
        }.to change { Encounter.count }.by(1)

        expect(response).to have_http_status(200)
        expect(Encounter.find(encounter[:id]).facility).to eq request_facility
      end

      it "associates patient with the encounter" do
        encounter = build_encounters_payload(build_record)
        patient = Patient.find(encounter["patient_id"])

        expect {
          post(:sync_from_user, params: {encounters: [encounter]}, as: :json)
        }.to change { Encounter.count }.by(1)

        expect(response).to have_http_status(200)
        expect(Encounter.find(encounter[:id]).patient).to eq patient
      end

      context "encounter contains observations from more than one facility" do
        let(:encounter) { build_encounters_payload(build_record) }
        before do
          # Adding two observations from separate facilities
          encounter[:observations][:blood_pressures].append(build_blood_pressure_payload)
          encounter[:observations][:blood_pressures].append(build_blood_pressure_payload)
        end
        it "does not create an encounter" do
          expect {
            post(:sync_from_user, params: {encounters: [encounter]}, as: :json)
          }.to_not change { Encounter.count }
        end

        it "returns an error in the response" do
          post(:sync_from_user, params: {encounters: [encounter]}, as: :json)
          expect(JSON(response.body)["errors"]).to eq(["schema" => ["Encounter observations belong to more than one facility"],
                                                       "id" => encounter["id"]])
        end
      end
    end
  end

  describe "GET sync: send data from server to device;" do
    it_behaves_like "a working V3 sync controller sending records"
    it_behaves_like "a working sync controller that supports region level sync"

    describe "v3 facility prioritisation" do
      it "syncs request facility's records first" do
        request_2_facility = create(:facility, facility_group: request_facility_group)

        patient_1 = create(:patient, registration_facility: request_facility)
        patient_2 = create(:patient, registration_facility: request_2_facility)

        create_record_list(2,
          patient: patient_1,
          facility: request_facility,
          updated_at: 3.minutes.ago)
        create_record_list(2,
          patient: patient_1,
          facility: request_facility,
          updated_at: 5.minutes.ago)
        create_record_list(2,
          patient: patient_2,
          facility: request_2_facility,
          updated_at: 7.minutes.ago)
        create_record_list(2,
          patient: patient_2,
          facility: request_2_facility,
          updated_at: 10.minutes.ago)

        # GET request 1
        set_authentication_headers
        get :sync_to_user, params: {limit: 4}
        response_1_body = JSON(response.body)

        record_ids = response_1_body["encounters"].map { |r| r["id"] }
        records = model.where(id: record_ids)
        expect(records.count).to eq 4
        expect(records.map(&:facility).to_set).to eq Set[request_facility]

        reset_controller

        # GET request 2
        get :sync_to_user, params: {limit: 4, process_token: response_1_body["process_token"]}
        response_2_body = JSON(response.body)

        record_ids = response_2_body["encounters"].map { |r| r["id"] }
        records = model.where(id: record_ids)
        expect(records.count).to eq 4
        expect(records.map(&:facility).to_set).to eq Set[request_facility, request_2_facility]
      end
    end
  end
end
