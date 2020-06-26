require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe SendPatientOtpSmsJob, type: :job do
  let!(:passport_authentication) { create(:passport_authentication) }
  let(:app_signature) { ENV['SIMPLE_APP_SIGNATURE'] }
  let(:otp_message) { "<#> #{passport_authentication.otp} is your BP Passport verification code\n#{app_signature}" }

  before do
    allow_any_instance_of(NotificationService).to receive(:send_sms)
  end

  it 'sends the OTP via SMS' do
    phone_number = passport_authentication.patient&.latest_mobile_number
    expect_any_instance_of(NotificationService).to receive(:send_sms).with(phone_number, otp_message)

    described_class.perform_now(passport_authentication)
  end
end
