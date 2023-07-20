require "swagger_helper"

describe "Import v4 API", swagger_doc: "v4/import.json" do
  before { Flipper.enable(:imports_api) }
  path "/import" do
    let(:organization) { FactoryBot.create(:organization) }
    let(:resource) { build_patient_import_resource }
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
        let(:import_request) { {"resources" => [build_patient_import_resource]} }
        run_test!
      end

      response "400", "Bad Request" do
        let(:HTTP_X_ORGANIZATION_ID) { organization.id }
        let(:Authorization) { "Bearer #{token.token}" }
        let(:import_request) { {"resources" => [{"invalid" => "invalid"}]} }
        run_test!
      end
    end
  end
end
