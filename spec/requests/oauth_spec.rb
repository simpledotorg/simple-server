require "rails_helper"

RSpec.describe "OAuth Credentials", type: :request do
  context "import API" do
    before { Flipper.enable(:imports_api) }
    context "when unauthorized" do
      let(:resource) { build_condition_import_resource }
      it "fails with HTTP 401" do
        put "/api/v4/import",
          headers: {"Content-Type": "application/json",
                    HTTP_X_ORGANIZATION_ID: SecureRandom.uuid},
          params: {resources: [resource]}.to_json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when authorization header present" do
      let(:organization) { FactoryBot.create(:organization) }
      let(:resource) { build_condition_import_resource }
      let(:machine_user) { FactoryBot.create(:machine_user, organization: organization) }
      let(:application) { FactoryBot.create(:oauth_application, owner: machine_user) }
      let(:token_write_scope) {
        FactoryBot.create(:oauth_access_token,
          application: application,
          scopes: "write",
          resource_owner_id: machine_user.id)
      }
      let(:token_invalid_scope) {
        FactoryBot.create(:oauth_access_token,
          application: application,
          scopes: "read",
          resource_owner_id: machine_user.id)
      }

      it "succeeds with HTTP 202 for valid token" do
        put "/api/v4/import",
          headers: {"Content-Type": "application/json",
                    Authorization: "Bearer " + token_write_scope.token,
                    HTTP_X_ORGANIZATION_ID: organization.id},
          params: {resources: [resource]}.to_json

        expect(response).to have_http_status(:accepted)
      end

      it "fails with HTTP 401 with an invalid token" do
        put "/api/v4/import",
          headers: {"Content-Type": "application/json",
                    Authorization: "Bearer invalidtoken",
                    HTTP_X_ORGANIZATION_ID: organization.id},
          params: {resources: [resource]}.to_json

        expect(response).to have_http_status(:unauthorized)
      end

      it "fails with HTTP 403 with an invalid scope" do
        put "/api/v4/import",
          headers: {"Content-Type": "application/json",
                    Authorization: "Bearer " + token_invalid_scope.token,
                    HTTP_X_ORGANIZATION_ID: organization.id},
          params: {resources: [resource]}.to_json

        expect(response).to have_http_status(:forbidden)
      end

      it "fails with HTTP 403 with an invalid organization" do
        put "/api/v4/import",
          headers: {"Content-Type": "application/json",
                    Authorization: "Bearer " + token_write_scope.token,
                    HTTP_X_ORGANIZATION_ID: SecureRandom.uuid},
          params: {resources: [resource]}.to_json

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
