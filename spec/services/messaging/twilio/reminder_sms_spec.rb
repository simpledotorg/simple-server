require "rails_helper"

RSpec.describe Messaging::Twilio::ReminderSms do
  specify { expect(described_class.new.communication_type).to eq("sms") }

  describe "SMS sender" do
    it "uses the production sender in production" do
      stub_const("SIMPLE_SERVER_ENV", "production")
      senders = %w[1234567890 1234567891 1234567892]

      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:fetch).with("TWILIO_APPOINTMENT_REMINDER_NUMBERS", "").and_return(senders.join(","))

      expect(senders).to include(described_class.new.sender_number)
    end

    it "uses the test number in test environments" do
      stub_const("SIMPLE_SERVER_ENV", "sandbox")
      senders = %w[1234567890 1234567891 1234567892]

      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:fetch).with("TWILIO_APPOINTMENT_REMINDER_NUMBERS", "").and_return(senders.join(","))

      expect(described_class.new.sender_number).to eq("+15005550006")
    end
  end

  describe ".send_message" do
    it "correctly calls the Twilio API" do
      client = double("TwilioClientDouble")
      allow(Twilio::REST::Client).to receive(:new).and_return(client)
      allow(client).to receive_message_chain("messages.create")
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
