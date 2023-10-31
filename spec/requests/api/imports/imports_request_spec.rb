require "rails_helper"

RSpec.describe "Import API", type: :request do
  before { Flipper.enable(:imports_api) }
  before { FactoryBot.create(:facility) } # needed for our bot import user
  let(:facility) { Facility.first }
  let(:facility_identifier) do
    create(:facility_business_identifier, facility: facility, identifier_type: :external_org_facility_id)
  end
  let(:patient) { create(:patient, assigned_facility: facility) }
  let(:patient_identifier) do
    create(:patient_business_identifier, patient: patient, identifier_type: :external_import_id)
  end
  let(:organization) { facility.facility_group.organization }
  let(:machine_user) { FactoryBot.create(:machine_user, organization: organization) }
  let(:application) { FactoryBot.create(:oauth_application, owner: machine_user) }
  let(:token) {
    FactoryBot.create(:oauth_access_token,
      application: application,
      scopes: "write",
      resource_owner_id: machine_user.id)
  }
  let(:route) { "/api/v4/import" }
  let(:auth_headers) do
    {"HTTP_X_ORGANIZATION_ID" => organization.id,
     "HTTP_AUTHORIZATION" => "Bearer #{token.token}"}
  end
  let(:headers) do
    {"ACCEPT" => "application/json", "CONTENT_TYPE" => "application/json"}.merge(auth_headers)
  end
  let(:invalid_payload) { {} }

  it "imports patient resources" do
    put route,
      params: {
        resources: [
          build_patient_import_resource
            .merge(managingOrganization: [{value: facility_identifier.identifier}])
            .except(:registrationOrganization)
        ]
      }.to_json,
      headers: headers

    expect(response.status).to eq(202)
  end

  it "imports appointment resources" do
    put route,
      params: {
        resources: [
          build_appointment_import_resource
            .merge(appointmentOrganization: {identifier: facility_identifier.identifier},
              participant: [{actor: {identifier: patient_identifier.identifier}}])
            .except(:appointmentCreationOrganization)
        ]
      }.to_json,
      headers: headers

    expect(response.status).to eq(202)
  end

  it "imports observation resources" do
    put route,
      params: {
        resources: [:blood_pressure, :blood_sugar].map do
          build_observation_import_resource(_1)
            .merge(performer: [{identifier: facility_identifier.identifier}],
              subject: {identifier: patient_identifier.identifier})
        end
      }.to_json,
      headers: headers

    expect(response.status).to eq(202)
  end

  it "imports medication request resources" do
    put route,
      params: {
        resources: [
          build_medication_request_import_resource
            .merge(performer: {identifier: facility_identifier.identifier},
              subject: {identifier: patient_identifier.identifier})
        ]
      }.to_json,
      headers: headers

    expect(response.status).to eq(202)
  end

  it "imports condition resources" do
    put route,
      params: {
        resources: [build_condition_import_resource.merge(subject: {identifier: patient_identifier.identifier})]
      }.to_json,
      headers: headers

    expect(response.status).to eq(202)
  end

  it "fails to import invalid resources" do
    put route, params: {resources: [invalid_payload]}.to_json, headers: headers

    expect(response.status).to eq(400)
  end
end
