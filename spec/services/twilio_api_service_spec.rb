require "rails_helper"

RSpec.describe TwilioApiService do
  let(:twilio_client) { double("TwilioClientDouble") }
  let(:fake_callback_url) { "http://localhost/callback" }
  let(:sender_sms_phone_number) { described_class::TWILIO_TEST_SMS_NUMBER }
  let(:sender_whatsapp_phone_number) { described_class::TWILIO_TEST_WHATSAPP_NUMBER }

  subject(:notification_service) { TwilioApiService.new }
  let(:recipient_phone_number) { "+918585858585" }
  let(:invalid_phone_number) { "+15005550001" } # this is twilio's hard-coded "invalid phone number"

  def stub_client
    allow(notification_service).to receive(:client).and_return(twilio_client)
  end

  describe "#send_whatsapp" do
    it "raises an error with a nil reason if the twilio error is not in our list" do
      stub_client
      response = double
      allow(response).to receive(:body).and_return({"code" => 20000})
      allow(response).to receive(:status_code).and_return(200) # this is just to stub the exception, it breaks otherwise

      allow(twilio_client).to receive_message_chain("messages.create").and_raise(
        Twilio::REST::RestError.new("An error", response)
      )

      expect {
        notification_service.send_whatsapp(
          recipient_number: recipient_phone_number,
          message: "test sms message",
          callback_url: fake_callback_url
        )
      }.to raise_error(an_instance_of(TwilioApiService::Error)) do |error|
        expect(error.reason).to be_nil
      end
    end
  end
end
