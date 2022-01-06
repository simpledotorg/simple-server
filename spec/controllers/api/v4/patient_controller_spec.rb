# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V4::PatientController, type: :controller do
  describe "#activate" do
    let!(:bp_passport) { create(:patient_business_identifier, identifier_type: "simple_bp_passport") }
    let(:patient) { bp_passport.patient }
    let!(:passport_authentication) { create(:passport_authentication, patient_business_identifier: bp_passport) }

    before do
      allow(SendPatientOtpSmsJob).to receive(:perform_later)
    end

    it "returns a successful response" do
      post :activate, params: {passport_id: bp_passport.identifier}
      expect(response.status).to eq(200)
    end

    it "send an OTP SMS" do
      expect(SendPatientOtpSmsJob).to receive(:perform_later).with(passport_authentication)
      post :activate, params: {passport_id: bp_passport.identifier}
    end

    it "returns a 404 response when BP passport ID does not exist" do
      post :activate, params: {passport_id: "some-identifier"}
      expect(response.status).to eq(404)
    end

    it "returns a 404 response when patient does not have any mobile numbers" do
      patient.phone_numbers.destroy_all

      post :activate, params: {passport_id: bp_passport.identifier}
      expect(response.status).to eq(404)
    end

    it "does not send an SMS when fixed OTPs are enabled" do
      Flipper.enable(:fixed_otp)

      expect(SendPatientOtpSmsJob).not_to receive(:perform_later)
      post :activate, params: {passport_id: bp_passport.identifier}
    end
  end

  describe "#login" do
    let!(:bp_passport) { create(:patient_business_identifier, identifier_type: "simple_bp_passport") }
    let(:patient) { bp_passport.patient }
    let!(:passport_authentication) { create(:passport_authentication, patient_business_identifier: bp_passport) }

    it "returns a successful response" do
      post :login, params: {passport_id: bp_passport.identifier, otp: passport_authentication.otp}
      expect(response.status).to eq(200)

      response_data = JSON.parse(response.body)
      expect(response_data).to match(
        "patient" => {
          "id" => patient.id,
          "access_token" => passport_authentication.reload.access_token,
          "passport" => {
            "id" => bp_passport.identifier,
            "shortcode" => bp_passport.shortcode
          }
        }
      )
    end

    context "when otp is wrong" do
      it "returns an unauthorized response" do
        post :login, params: {passport_id: bp_passport.identifier, otp: "wrong-otp"}
        expect(response.status).to eq(401)
      end
    end

    context "when BP passport ID is wrong" do
      it "returns an unauthorized response" do
        post :login, params: {passport_id: "wrong-identifier", otp: passport_authentication.otp}
        expect(response.status).to eq(401)
      end
    end

    context "when an OTP is expired" do
      before { passport_authentication.tap(&:expire_otp).save! }

      it "returns an unauthorized response" do
        post :login, params: {passport_id: bp_passport.identifier, otp: passport_authentication.otp}
        expect(response.status).to eq(401)
      end
    end

    context "when an OTP is re-used" do
      it "returns an unauthorized response" do
        post :login, params: {passport_id: bp_passport.identifier, otp: passport_authentication.otp}
        post :login, params: {passport_id: bp_passport.identifier, otp: passport_authentication.otp}

        expect(response.status).to eq(401)
      end
    end
  end

  describe "#show" do
    let!(:bp_passport) { create(:patient_business_identifier, identifier_type: "simple_bp_passport") }
    let(:patient) { bp_passport.patient }
    let!(:passport_authentication) { create(:passport_authentication, patient_business_identifier: bp_passport) }
    let!(:access_token) { passport_authentication.access_token }

    before do
      request.headers["Accept"] = "application/json"
      request.headers["Authorization"] = "Bearer #{access_token}"
      request.headers["X-Patient-Id"] = patient.id
    end

    it "returns a successful response" do
      get :show
      expect(response.status).to eq(200)
    end

    context "response schema" do
      render_views

      it "returns patient information in the correct schema" do
        get :show
        response_data = JSON.parse(response.body)
        expected_schema = Api::V4::Schema.patient_response.merge(definitions: Api::V4::Schema.all_definitions)
        expect(JSON::Validator.validate(expected_schema, response_data)).to eq(true)
      end
    end

    context "when Authorization header is incorrect" do
      before do
        request.headers["Authorization"] = "Bearer nope-wrong-token-sorry"
      end

      it "returns an unauthorized response" do
        get :show
        expect(response.status).to eq(401)
      end
    end

    context "when X-Patient-Id header is incorrect" do
      before do
        request.headers["X-Patient-Id"] = "nope-wrong-id-sorry"
      end

      it "returns an unauthorized response" do
        get :show
        expect(response.status).to eq(401)
      end
    end
  end
end
