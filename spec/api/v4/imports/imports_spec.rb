require "swagger_helper"

describe "Import v4 API", swagger_doc: "v4/import.json" do
  before { Flipper.enable(:imports_api) }
  before { FactoryBot.create(:facility) }
  path "/import" do
    let(:facility) { Facility.first }
    let(:facility_identifier) do
      create(:facility_business_identifier, facility: facility, identifier_type: :external_org_facility_id)
    end
    let(:patient) { create(:patient, assigned_facility: facility) }
    let(:patient_identifier) do
      create(:patient_business_identifier, patient: patient, identifier_type: :external_import_id)
    end
    let(:organization) { facility.organization }
    let(:machine_user) { FactoryBot.create(:machine_user, organization: organization) }
    let(:application) { FactoryBot.create(:oauth_application, owner: machine_user) }
    let(:token) {
      FactoryBot.create(:oauth_access_token,
        application: application,
        scopes: "write",
        resource_owner_id: machine_user.id)
    }
    put "Send bulk resources to Simple" do
      tags "import"
      security [access_token: [], import_auth: ["write"]]
      parameter name: :HTTP_X_ORGANIZATION_ID,
        in: :header,
        type: :uuid,
        description: "UUID of organization. The header key should be passed as 'X-Organization-ID'."
      parameter name: :import_request, in: :body, schema: Api::V4::Imports.import_request_payload

      response "202", "Accepted" do
        let(:HTTP_X_ORGANIZATION_ID) { organization.id }
        let(:Authorization) { "Bearer #{token.token}" }
        let(:import_request) do
          {"resources" => [build_condition_import_resource
            .merge(subject: {identifier: patient_identifier.identifier})]}
        end
        run_test!
      end

      response "400", "Bad Request" do
        let(:HTTP_X_ORGANIZATION_ID) { organization.id }
        let(:Authorization) { "Bearer #{token.token}" }
        let(:import_request) { {"resources" => [{"invalid" => "invalid"}]} }
        run_test!
      end

      response "403", "Forbidden" do
        let(:HTTP_X_ORGANIZATION_ID) { "wrong_org" }
        let(:Authorization) { "Bearer #{token.token}" }
        let(:import_request) { {"resources" => [{"doesn't" => "matter"}]} }
        run_test!
      end
    end
  end
end
