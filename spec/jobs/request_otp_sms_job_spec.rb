require "rails_helper"
require "sidekiq/testing"

RSpec.describe RequestOtpSmsJob, type: :job do
  let!(:user) { create(:user, phone_number: "1234567890") }
  let(:app_signature) { ENV["SIMPLE_APP_SIGNATURE"] }
  let(:otp_message) { "<#> #{user.otp} is your Simple verification code\n#{app_signature}" }

  it "sends the OTP via SMS" do
    expect_any_instance_of(Messaging::Twilio::OtpSms).to receive(:send_message).with(
      recipient_number: user.localized_phone_number, message: otp_message
    )

    described_class.perform_now(user)
  end

  it "does not raise an exception if twilio responds with invalid phone number error" do
    allow_any_instance_of(Messaging::Twilio::OtpSms).to receive(:send_message).and_raise(Messaging::Twilio::Error.new("An error", 21211))
    described_class.perform_now(user)
  end
end
