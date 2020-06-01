require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe RequestOtpSmsJob, type: :job do
  let!(:user) { create(:user, phone_number: '1234567890') }
  let(:app_signature) { ENV["SIMPLE_APP_SIGNATURE"] }
  let(:otp_message) { "<#> #{user.otp} is your Simple verification code\\n#{app_signature}" }

  before do
    allow_any_instance_of(NotificationService).to receive(:send_sms)
  end

  it 'sends the OTP via SMS' do
    expect_any_instance_of(NotificationService).to receive(:send_sms).with(user.phone_number, otp_message)

    described_class.perform_now(user)
  end
end
