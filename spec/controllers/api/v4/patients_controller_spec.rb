require "rails_helper"

def set_headers(user, facility)
  request.env["HTTP_X_USER_ID"] = user.id
  request.env["HTTP_X_FACILITY_ID"] = facility.id
  request.env["HTTP_AUTHORIZATION"] = "Bearer #{user.access_token}"
  request.headers["Accept"] = "application/json"
end

RSpec::Matchers.define :a_patient_lookup_audit_log do |expected_log|
  match do |actual_log|
    (expected_log.to_a - JSON.parse(actual_log, symbolize_names: true).to_a).empty?
  end
end

RSpec.describe Api::V4::PatientsController, type: :controller do
  describe "#lookup" do
    it "returns patient in expected response schema" do
      patient = create(:patient)
      set_headers(patient.registration_user, patient.registration_facility)

      post :lookup, params: {identifier: patient.business_identifiers.first.identifier}, as: :json
      expect(response.status).to eq 200
      response_data = JSON.parse(response.body)
      expected_schema = Api::V4::Schema.lookup_response.merge(definitions: Api::V4::Schema.all_definitions)
      expect(JSON::Validator.validate(expected_schema, response_data)).to eq(true)
    end

    it "returns bad request if identifier is not present in the request" do
      patient = create(:patient)
      set_headers(patient.registration_user, patient.registration_facility)

      post :lookup, params: {identifier: ""}, as: :json
      expect(response.status).to eq 400
    end

    it "returns all information about a patient" do
      patient = create(:patient)
      add_visits(2, patient: patient, facility: patient.registration_facility, user: patient.registration_user)
      set_headers(patient.registration_user, patient.registration_facility)

      post :lookup, params: {identifier: patient.business_identifiers.first.identifier}, as: :json
      response_patient = JSON.parse(response.body).with_indifferent_access[:patients][0]
      expected_attrs = [:address, :appointments, :blood_pressures, :blood_sugars, :business_identifiers,
        :medical_history, :phone_numbers, :prescription_drugs]
      expect(response_patient.values_at(*expected_attrs)).to all be_present
      expect(response_patient[:blood_pressures].count).to eq 2
      expect(response_patient[:blood_sugars].count).to eq 2
      expect(response_patient[:appointments].count).to eq 2
    end

    it "sends a nil medical history for patients without a medical history" do
      patient = create(:patient, :without_medical_history)
      set_headers(patient.registration_user, patient.registration_facility)

      post :lookup, params: {identifier: patient.business_identifiers.first.identifier}, as: :json
      expect(response.status).to eq 200

      response_patient = JSON.parse(response.body).with_indifferent_access[:patients][0]
      expect(response_patient[:medical_history]).to eq nil
    end

    it "returns multiple patients with the same identifier, irrespective of identifier type" do
      patient_1 = create(:patient)
      patient_2 = create(:patient, registration_facility: patient_1.registration_facility)
      patient_1.business_identifiers.first.update(
        identifier_type: PatientBusinessIdentifier.identifier_types.values.first
      )

      patient_2.business_identifiers.first.update(
        identifier: patient_1.business_identifiers.first.identifier,
        identifier_type: PatientBusinessIdentifier.identifier_types.values.second
      )

      set_headers(patient_1.registration_user, patient_1.registration_facility)

      post :lookup, params: {identifier: patient_1.business_identifiers.first.identifier}, as: :json
      response_data = JSON.parse(response.body).with_indifferent_access
      expect(response_data[:patients].count).to eq 2
    end

    it "returns nothing when an identifier is not discarded but patient is discarded" do
      patient_1 = create(:patient)
      business_identifier = patient_1.business_identifiers.first
      patient_1.business_identifiers.first.update(
        identifier_type: PatientBusinessIdentifier.identifier_types.values.first
      )

      set_headers(patient_1.registration_user, patient_1.registration_facility)
      patient_1.discard_data
      business_identifier.reload.undiscard

      post :lookup, params: {identifier: patient_1.business_identifiers.first.identifier}, as: :json
      expect(response.status).to eq(404)
    end

    it "sets the retention as temporary and specifies the duration when patient is outside syncable region" do
      facility_group = create(:facility_group, name: "fg2", state: "State 1")

      facility_1 = create(:facility, name: "facility1", facility_group: facility_group, zone: "Block XYZ")
      facility_2 = create(:facility, name: "facility2", facility_group: facility_group, zone: "Block 123")

      patient_1 = create(:patient, registration_facility: facility_1)
      patient_2 = create(:patient, registration_facility: facility_2)

      identifier = patient_1.business_identifiers.first.identifier
      patient_2.business_identifiers.first.update(identifier: identifier)

      user = create(:user, registration_facility: facility_1)
      set_headers(user, facility_1)
      request.env["HTTP_X_SYNC_REGION_ID"] = facility_1.region.block_region.id
      ENV["TEMPORARY_RETENTION_DURATION_SECONDS"] = "99"

      post :lookup, params: {identifier: identifier}, as: :json
      response_patients = JSON.parse(response.body).with_indifferent_access[:patients]
      response_patient_1 = response_patients.find { |patients| patients[:id] == patient_1.id }
      response_patient_2 = response_patients.find { |patients| patients[:id] == patient_2.id }

      expect(response_patient_1[:retention]).to eq({type: "permanent"}.with_indifferent_access)
      expect(response_patient_2[:retention]).to eq({type: "temporary", duration_seconds: 99}.with_indifferent_access)
    end

    it "validates state level access" do
      # 2 patients from the same state
      facility_group_state_1 = create(:facility_group, state: "State 1")
      facility_1 = create(:facility, facility_group: facility_group_state_1)
      facility_2 = create(:facility, facility_group: facility_group_state_1)
      patient = create(:patient, registration_facility: facility_1)
      patient_from_same_state = create(:patient, registration_facility: facility_2)

      # one patient from another state
      facility_group_state_2 = create(:facility_group, state: "State 2")
      facility_3 = create(:facility, facility_group: facility_group_state_2)
      patient_from_another_state = create(:patient, registration_facility: facility_3)

      patient_from_another_state.business_identifiers.first.update(
        identifier: patient.business_identifiers.first.identifier
      )
      patient_from_same_state.business_identifiers.first.update(
        identifier: patient.business_identifiers.first.identifier
      )
      set_headers(patient.registration_user, patient.registration_facility)

      post :lookup, params: {identifier: patient.business_identifiers.first.identifier}, as: :json
      response_data = JSON.parse(response.body).with_indifferent_access
      expect(response_data[:patients].count).to eq 2
      expect(response_data[:patients].pluck(:id)).to match_array([patient.id, patient_from_same_state.id])
    end

    it "triggers an audit log" do
      patient = create(:patient)
      set_headers(patient.registration_user, patient.registration_facility)

      expect(PatientLookupAuditLogJob).to receive(:perform_async).with(a_patient_lookup_audit_log(
        user_id: patient.registration_user.id,
        facility_id: patient.registration_facility.id,
        patient_ids: [patient.id],
        identifier: patient.business_identifiers.first.identifier
      ))
      post :lookup, params: {identifier: patient.business_identifiers.first.identifier}, as: :json
    end

    it "increments a statsd metric" do
      patient = create(:patient)
      set_headers(patient.registration_user, patient.registration_facility)
      expect(Statsd.instance).to receive(:increment).with("OnlineLookup.temporary", {tags: [patient.registration_facility.state, patient.registration_user.id]})
      post :lookup, params: {identifier: patient.business_identifiers.first.identifier}, as: :json
    end
  end
end
