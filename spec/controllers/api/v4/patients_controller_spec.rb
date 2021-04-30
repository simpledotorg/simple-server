require "rails_helper"

def set_headers(user, facility)
  request.env["HTTP_X_USER_ID"] = user.id
  request.env["HTTP_X_FACILITY_ID"] = facility.id
  request.env["HTTP_AUTHORIZATION"] = "Bearer #{user.access_token}"
  request.headers["Accept"] = "application/json"
end

RSpec.describe Api::V4::PatientsController, type: :controller do
  describe "#lookup" do
    render_views

    it "returns patient in expected response schema" do
      patient = create(:patient)
      set_headers(patient.registration_user, patient.registration_facility)

      get :lookup, params: {identifier: patient.business_identifiers.first.identifier}, as: :json
      expect(response.status).to eq 200
      response_data = JSON.parse(response.body)
      expected_schema = Api::V4::Schema.lookup_response.merge(definitions: Api::V4::Schema.all_definitions)
      expect(JSON::Validator.validate(expected_schema, response_data)).to eq(true)
    end

    xit "returns all information about a patient" do
      # TODO: confirm the response schema, and write the rest of the assertions here
      patient = create(:patient)
      add_visits(2, patient: patient, facility: patient.registration_facility, user: patient.registration_user)
      set_headers(patient.registration_user, patient.registration_facility)

      get :lookup, params: {identifier: patient.business_identifiers.first.identifier}, as: :json
      response_patient = JSON.parse(response.body).with_indifferent_access[:patients][0]
      expect(response_patient[:blood_pressures].count).to eq 2
      expect(response_patient[:blood_sugars].count).to eq 2
      expect(response_patient[:appointments].count).to eq 2
    end

    xit "returns the list of business identifiers" do
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

      get :lookup, params: {identifier: patient_1.business_identifiers.first.identifier}, as: :json
      response_data = JSON.parse(response.body).with_indifferent_access
      expect(response_data[:patients].count).to eq 2
    end

    it "returns retention information" do
      patient = create(:patient)
      set_headers(patient.registration_user, patient.registration_facility)

      get :lookup, params: {identifier: patient.business_identifiers.first.identifier}, as: :json
      response_data = JSON.parse(response.body).with_indifferent_access
      expect(response_data[:retention]).to eq({type: "temporary", duration_seconds: 3600}.with_indifferent_access)
    end

    xit "sets the retention type to be permanent when the patient is syncable to the user" do
    end

    it "validates state level access" do
      patient = create(:patient)
      patient_from_another_state = create(:patient)
      patient_from_another_state.business_identifiers.first.update(
        identifier: patient.business_identifiers.first.identifier
      )
      set_headers(patient.registration_user, patient.registration_facility)

      get :lookup, params: {identifier: patient.business_identifiers.first.identifier}, as: :json
      response_data = JSON.parse(response.body).with_indifferent_access
      expect(response_data[:patients].count).to eq 1
      expect(response_data[:patients].first[:id]).to eq patient.id
    end
  end
end
