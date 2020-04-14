require 'swagger_helper'

describe 'Patient v4 API', swagger_doc: 'v4/swagger.json' do
  path '/patient/activate' do
    post 'Trigger an OTP to be sent to a patient' do
      tags 'Patient'
      parameter name: :passport_id, in: :body, schema: Api::V4::Schema.patient_activate_request, description: 'Patient\'s BP Passport UUID'

      before :each do
        sms_notification_service = double(SmsNotificationService.new(nil, nil))
        allow(SmsNotificationService).to receive(:new).and_return(sms_notification_service)
        allow(sms_notification_service).to receive(:send_request_otp_sms).and_return(true)
      end

      response '200', 'patient is found and an OTP is sent to their phone' do
        let(:bp_passport) { create(:patient_business_identifier, identifier_type: 'simple_bp_passport') }
        let(:passport_id) { { passport_id: bp_passport.identifier } }

        run_test!
      end

      response '404', 'incorrect passport id' do
        let(:passport_id) { { passport_id: 'itsafake-uuid-0000-0000-000000000000' } }

        run_test!
      end
    end
  end
end
