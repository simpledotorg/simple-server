# frozen_string_literal: true

require "rails_helper"
require "sidekiq/testing"

RSpec.describe RequestOtpSmsJob, type: :job do
  let!(:user) { create(:user, phone_number: "1234567890") }
  let(:app_signature) { ENV["SIMPLE_APP_SIGNATURE"] }
  let(:otp_message) { "<#> #{user.otp} is your Simple verification code\n#{app_signature}" }

  before do
    allow_any_instance_of(TwilioApiService).to receive(:send_sms)
  end

  it "sends the OTP via SMS" do
    context = {
      calling_class: "RequestOtpSmsJob",
      user_id: user.id,
      communication_type: :sms
    }
    expect_any_instance_of(TwilioApiService).to receive(:send_sms).with(
      recipient_number: user.localized_phone_number, message: otp_message, context: context
    )

    described_class.perform_now(user)
  end

  it "does not raise an exception if twilio responds with invalid phone number error" do
    allow_any_instance_of(TwilioApiService).to receive(:send_sms).and_raise(TwilioApiService::Error.new("An error", 21211))
    described_class.perform_now(user)
  end
end
