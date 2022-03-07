require "rails_helper"

RSpec.describe Messaging::Twilio::Whatsapp do
  specify { expect(described_class.new.communication_type).to eq("whatsapp") }

  describe "Whatsapp sender" do
    it "uses the production sender in production" do
      stub_const("SIMPLE_SERVER_ENV", "production")

      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:fetch).with("TWILIO_PHONE_NUMBER").and_return("1234567890")

      expect(described_class.new.sender_number).to eq("whatsapp:1234567890")
    end

    it "uses the test number in test environments" do
      stub_const("SIMPLE_SERVER_ENV", "sandbox")

      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:fetch).with("TWILIO_PHONE_NUMBER").and_return("1234567890")

      expect(described_class.new.sender_number).to eq("whatsapp:+14155238886")
    end
  end

  describe ".send_message" do
    it "correctly calls the Twilio API" do
      client = double("TwilioClientDouble")
      allow(Twilio::REST::Client).to receive(:new).and_return(client)
      allow(client).to receive_message_chain("messages.create")
      sender_whatsapp_phone_number = described_class::TWILIO_TEST_WHATSAPP_NUMBER
      recipient_phone_number = "+918585858585"
      callback_url = "https://localhost/api/v3/twilio_sms_delivery"

      expect(client).to receive_message_chain("messages.create").with(
        from: "whatsapp:#{sender_whatsapp_phone_number}",
        to: "whatsapp:#{recipient_phone_number}",
        status_callback: callback_url,
        body: "test whatsapp message"
      )

      described_class.send_message(
        recipient_number: recipient_phone_number,
        message: "test whatsapp message"
      )
    end
  end
end
