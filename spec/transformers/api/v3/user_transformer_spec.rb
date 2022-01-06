# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V3::UserTransformer do
  describe "to_response" do
    let!(:user) { create(:user) }

    subject(:response) { described_class.to_response(user) }

    before do
      allow(Api::V3::Transformer).to receive(:to_response)
        .with(user)
        .and_return(
          "user" => "attributes",
          "otp" => "123456",
          "otp_expires_at" => Time.now,
          "access_token" => "supersecretaccesstoken",
          "logged_in_at" => Time.now,
          "role" => "admin",
          "organization_id" => "organization-id"
        )
    end

    it "includes user attributes" do
      expect(response).to include("user" => "attributes")
    end

    it "includes associated params" do
      expect(response).to include(
        "registration_facility_id" => user.registration_facility.id,
        "phone_number" => user.phone_number,
        "password_digest" => user.phone_number_authentication.password_digest
      )
    end

    it "excludes sensitive params" do
      expect(response).not_to include(
        "otp",
        "otp_expires_at",
        "access_token",
        "logged_in_at",
        "role",
        "organization_id"
      )
    end
  end
end
