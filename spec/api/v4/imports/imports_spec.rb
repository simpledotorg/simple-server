require "swagger_helper"

describe "Import v4 API", swagger_doc: "v4/import.json" do
  before { Flipper.enable(:imports_api) }
  path "/import" do
    put "Send bulk resources to Simple" do
      tags "import"
      security [access_token: [], import_auth: ["write"]]
      parameter name: :organization_header,
        in: :header,
        type: :uuid,
        description: "UUID of organization"
      parameter name: :import_request, in: :body, schema: Api::V4::Imports.import_request_payload

      response "202", "Accepted" do
        let(:organization_header) { SecureRandom.uuid }
        let(:Authorization) { "Bearer #{::Base64.strict_encode64("bogusbogus")}" }
        let(:import_request) { {"resources" => [build_patient_import_resource]} }
        run_test!
      end

      response "400", "Bad Request" do
        let(:organization_header) { SecureRandom.uuid }
        let(:Authorization) { "Bearer #{::Base64.strict_encode64("bogusbogus")}" }
        let(:import_request) { {"resources" => [{"invalid" => "invalid"}]} }
        run_test!
      end
    end
  end
end
