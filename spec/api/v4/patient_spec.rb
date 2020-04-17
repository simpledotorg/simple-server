require 'swagger_helper'

describe 'Patient v4 API', swagger_doc: 'v4/swagger.json' do
  path '/patient/activate' do
    post 'Request an OTP to be sent to a patient' do
      tags 'Patient'
      parameter name: :request_body, in: :body, schema: Api::V4::Schema.patient_activate_request, description: 'Patient\'s BP Passport UUID'

      before :each do
        sms_notification_service = double(SmsNotificationService.new(nil, nil))
        allow(SmsNotificationService).to receive(:new).and_return(sms_notification_service)
        allow(sms_notification_service).to receive(:send_patient_activate_sms).and_return(true)
      end

      response '200', 'Patient is found and an OTP is sent to their phone' do
        let(:bp_passport) { create(:patient_business_identifier, identifier_type: 'simple_bp_passport') }
        let(:request_body) { { passport_id: bp_passport.identifier } }

        run_test!
      end

      response '404', 'Incorrect passport id' do
        let(:request_body) { { passport_id: 'itsafake-uuid-0000-0000-000000000000' } }

        run_test!
      end
    end
  end

  path '/patient/login' do
    post 'Log in a patient with BP Passport UUID and OTP' do
      tags 'Patient'
      parameter name: :request_body, in: :body, schema: Api::V4::Schema.patient_login_request, description: 'Patient\'s BP Passport UUID and OTP'

      response '200', 'Correct OTP is submitted and API credentials are returned' do
        let(:bp_passport) { create(:patient_business_identifier, identifier_type: 'simple_bp_passport') }
        let(:passport_authentication) { create(:passport_authentication, patient_business_identifier: bp_passport) }
        let(:request_body) { { passport_id: bp_passport.identifier, otp: passport_authentication.otp } }

        schema Api::V4::Schema.patient_login_response
        run_test!
      end

      response '401', 'Incorrect BP Passport UUID or OTP' do
        let(:bp_passport) { create(:patient_business_identifier, identifier_type: 'simple_bp_passport') }
        let!(:passport_authentication) { create(:passport_authentication, patient_business_identifier: bp_passport) }
        let(:request_body) { { passport_id: bp_passport.identifier, otp: 'wrong' } }

        run_test!
      end
    end
  end
end
