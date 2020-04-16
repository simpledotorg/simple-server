require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe SendPatientOtpSmsJob, type: :job do
  Sidekiq::Testing.fake!

  let!(:passport_authentication) { create(:passport_authentication) }
  let!(:sms_notification_service) { double(SmsNotificationService.new(nil, nil)) }

  it 'calls off to the SMSNotificationService to deliver the otp SMS' do
    expect(SmsNotificationService)
      .to receive(:new)
            .with(passport_authentication.patient.latest_mobile_number, ENV['TWILIO_PHONE_NUMBER'])
            .and_return(sms_notification_service)

    expect(sms_notification_service)
      .to receive(:send_patient_request_otp_sms)
            .with(passport_authentication.otp)
            .and_return(true)

    described_class.perform_later(passport_authentication)

    Sidekiq::Worker.drain_all
  end
end
