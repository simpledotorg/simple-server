require "rails_helper"

RSpec.describe Messaging::Twilio::OtpSms do
  specify { expect(described_class.communication_type).to eq("sms") }

  describe "SMS sender" do
    it "uses the production sender in production" do
      stub_const("SIMPLE_SERVER_ENV", "production")

      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:fetch).with("TWILIO_PHONE_NUMBER").and_return("1234567890")

      expect(described_class.new.sender_number).to eq("1234567890")
    end

    it "uses the test number in test environments" do
      stub_const("SIMPLE_SERVER_ENV", "sandbox")

      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:fetch).with("TWILIO_PHONE_NUMBER").and_return("1234567890")

      expect(described_class.new.sender_number).to eq("+15005550006")
    end
  end

  describe ".send_message" do
    it "correctly calls the Twilio API" do
      client = double("TwilioClientDouble")
      response = double("TwilioApiResponse")
      allow(Twilio::REST::Client).to receive(:new).and_return(client)
      allow(response).to receive(:sid).and_return("1234")
      allow(response).to receive(:status).and_return("sent")
      allow(client).to receive_message_chain("messages.create").and_return(response)
      sender_sms_phone_number = described_class::TWILIO_TEST_SMS_NUMBER
      recipient_phone_number = "+918585858585"
      callback_url = "https://localhost/api/v3/twilio_sms_delivery"

      expect(client).to receive_message_chain("messages.create").with(
        from: sender_sms_phone_number,
        to: recipient_phone_number,
        status_callback: callback_url,
        body: "test sms message"
      )

      described_class.send_message(
        recipient_number: recipient_phone_number,
        message: "test sms message"
      )
    end
  end
end
