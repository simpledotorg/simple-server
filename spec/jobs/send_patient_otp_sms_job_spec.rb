require "rails_helper"
require "sidekiq/testing"

RSpec.describe SendPatientOtpSmsJob, type: :job do
  it "sends the OTP via SMS" do
    passport_authentication = create(:passport_authentication)
    app_signature = ENV["SIMPLE_APP_SIGNATURE"]
    otp_message = "<#> #{passport_authentication.otp} is your BP Passport verification code\n#{app_signature}"

    client = double("Messaging::Twilio::OtpSms")
    allow(Messaging::Twilio::OtpSms).to receive(:new).and_return(client)
    phone_number = passport_authentication.patient&.latest_mobile_number

    expect(client).to receive(:send_message).with(
      recipient_number: phone_number,
      message: otp_message
    )

    described_class.perform_now(passport_authentication)
  end
end
