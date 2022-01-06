# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V4::UserTransformer do
  describe "to_response" do
    let!(:user) { create(:user, teleconsultation_facilities: [create(:facility)]) }
    let(:user_attributes) do
      user
        .attributes
        .merge("otp" => "123456",
          "otp_expires_at" => Time.current,
          "access_token" => "access token string",
          "logged_in_at" => Time.current)
    end

    subject(:response) { described_class.to_response(user) }

    before do
      allow(Api::V4::Transformer).to receive(:to_response)
        .with(user)
        .and_return(user_attributes)
    end

    it "includes user attributes" do
      expect(response).to include("id" => user.id,
        "full_name" => user.full_name,
        "sync_approval_status" => user.sync_approval_status,
        "sync_approval_status_reason" => user.sync_approval_status_reason,
        "teleconsultation_phone_number" => user.full_teleconsultation_phone_number)
    end

    it "includes time stamps" do
      expect(response).to include("deleted_at",
        "created_at",
        "updated_at")
    end

    it "includes associated params" do
      expect(response).to include("registration_facility_id" => user.registration_facility.id,
        "phone_number" => user.phone_number,
        "password_digest" => user.phone_number_authentication.password_digest,
        "capabilities" => {can_teleconsult: "yes"})
    end

    it "excludes sensitive params" do
      expect(response).not_to include("otp",
        "otp_expires_at",
        "access_token",
        "logged_in_at",
        "role",
        "organization_id")
    end
  end

  describe "to_find_response" do
    let!(:user) { create(:user) }
    let(:user_attributes) do
      {
        "id" => "123",
        "sync_approval_status" => "approved",
        "other" => "unnecessary",
        "field" => "values",
        "password_digest" => "supersecretdigest",
        "otp" => "123456",
        "otp_expires_at" => Time.current,
        "access_token" => "access token string",
        "logged_in_at" => Time.current
      }
    end

    subject(:response) { described_class.to_find_response(user) }

    before do
      allow(described_class).to receive(:to_response)
        .with(user)
        .and_return(user_attributes)
    end

    it "includes limited params" do
      expect(response).to include(
        "id" => "123",
        "sync_approval_status" => "approved"
      )
    end

    it "excludes other params" do
      expect(response).not_to include("other", "field")
    end

    it "excludes sensitive params" do
      expect(response).not_to include("password_digest",
        "otp",
        "otp_expires_at",
        "access_token",
        "logged_in_at",
        "role",
        "organization_id")
    end
  end
end
