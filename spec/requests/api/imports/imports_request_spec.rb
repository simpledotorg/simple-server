require "rails_helper"

RSpec.describe "Import API", type: :request do
  before { Flipper.enable(:imports_api) }
  before { FactoryBot.create(:facility) } # needed for our bot import user

  let(:organization) { FactoryBot.create(:organization) }
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
  let(:payload) { build_patient_import_resource }
  let(:invalid_payload) { {} }

  it "imports patient resources" do
    put route, params: {resources: [payload]}.to_json, headers: headers

    expect(response.status).to eq(202)
  end

  it "fails to import invalid resources" do
    put route, params: {resources: [invalid_payload]}.to_json, headers: headers

    expect(response.status).to eq(400)
  end
end
