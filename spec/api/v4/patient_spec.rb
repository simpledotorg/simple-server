# frozen_string_literal: true

require "swagger_helper"

describe "Patient v4 API", swagger_doc: "v4/swagger.json" do
  path "/patient/activate" do
    post "Request an OTP to be sent to a patient" do
      tags "Patient"
      parameter name: :request_body, in: :body, schema: Api::V4::Schema.patient_activate_request, description: "Patient's BP Passport UUID"

      before :each do
        allow(SendPatientOtpSmsJob).to receive(:perform_later).with(instance_of(PassportAuthentication))
      end

      response "200", "Patient is found and an OTP is sent to their phone" do
        let(:bp_passport) { create(:patient_business_identifier, identifier_type: "simple_bp_passport") }
        let(:request_body) { {passport_id: bp_passport.identifier} }

        run_test!
      end

      response "404", "Incorrect passport id" do
        let(:request_body) { {passport_id: "itsafake-uuid-0000-0000-000000000000"} }

        run_test!
      end
    end
  end

  path "/patient/login" do
    post "Log in a patient with BP Passport UUID and OTP" do
      tags "Patient"
      parameter name: :request_body, in: :body, schema: Api::V4::Schema.patient_login_request, description: "Patient's BP Passport UUID and OTP"

      response "200", "Correct OTP is submitted and API credentials are returned" do
        let(:bp_passport) { create(:patient_business_identifier, identifier_type: "simple_bp_passport") }
        let(:passport_authentication) { create(:passport_authentication, patient_business_identifier: bp_passport) }
        let(:request_body) { {passport_id: bp_passport.identifier, otp: passport_authentication.otp} }

        schema Api::V4::Schema.patient_login_response
        run_test!
      end

      response "401", "Incorrect BP Passport UUID or OTP" do
        let(:bp_passport) { create(:patient_business_identifier, identifier_type: "simple_bp_passport") }
        let!(:passport_authentication) { create(:passport_authentication, patient_business_identifier: bp_passport) }
        let(:request_body) { {passport_id: bp_passport.identifier, otp: "wrong"} }

        run_test!
      end
    end
  end

  path "/patient" do
    get "Fetch patient information" do
      tags "Patient"
      security [access_token: [], patient_id: []]
      parameter name: "HTTP_X_PATIENT_ID", in: :header, type: :uuid

      response "200", "Patient information is returned" do
        let(:bp_passport) { create(:patient_business_identifier, identifier_type: "simple_bp_passport") }
        let(:passport_authentication) { create(:passport_authentication, patient_business_identifier: bp_passport) }
        let(:request_body) { {passport_id: bp_passport.identifier, otp: passport_authentication.otp} }

        let(:HTTP_X_PATIENT_ID) { passport_authentication.patient.id }
        let(:Authorization) { "Bearer #{passport_authentication.access_token}" }

        schema Api::V4::Schema.patient_response
        run_test!
      end

      response "401", "Invalid access token" do
        let(:bp_passport) { create(:patient_business_identifier, identifier_type: "simple_bp_passport") }
        let(:passport_authentication) { create(:passport_authentication, patient_business_identifier: bp_passport) }
        let(:request_body) { {passport_id: bp_passport.identifier, otp: passport_authentication.otp} }

        let(:HTTP_X_PATIENT_ID) { passport_authentication.patient.id }
        let(:Authorization) { "Bearer wrong-token" }

        run_test!
      end

      response "401", "Invalid patient ID header" do
        let(:bp_passport) { create(:patient_business_identifier, identifier_type: "simple_bp_passport") }
        let(:passport_authentication) { create(:passport_authentication, patient_business_identifier: bp_passport) }
        let(:request_body) { {passport_id: bp_passport.identifier, otp: passport_authentication.otp} }

        let(:HTTP_X_PATIENT_ID) { "wrong-patient-id" }
        let(:Authorization) { "Bearer #{passport_authentication.access_token}" }

        run_test!
      end
    end
  end
end
