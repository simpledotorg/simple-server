require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe RequestOtpSmsJob, type: :job do
  Sidekiq::Testing.fake!

  let!(:user) { create(:user, phone_number: '1234567890') }
  let!(:sms_notification_service) { double(SmsNotificationService.new(nil, nil)) }

  before do
    allow(ENV).to receive(:[]).with('TWILIO_PHONE_NUMBER').and_return('123456')
  end

  it 'calls off to the SMSNotificationService to deliver the otp SMS' do
    expect(SmsNotificationService)
      .to receive(:new)
            .with(user.phone_number, ENV['TWILIO_PHONE_NUMBER'])
            .and_return(sms_notification_service)

    expect(sms_notification_service)
      .to receive(:send_request_otp_sms)
            .with(user.otp)
            .and_return(true)

    described_class.perform_later(user)

    Sidekiq::Worker.drain_all
  end
end
