require 'rails_helper'

RSpec.describe NotificationService do
  let(:twilio_client) { double('TwilioClientDouble') }
  let(:fake_callback_url) { "http://localhost/callback" }
  let(:sender_phone_number) { ENV.fetch('TWILIO_PHONE_NUMBER') }

  subject(:notification_service) { NotificationService.new }

  before do
    # Fake the internal Twilio client
    allow(notification_service).to receive(:client).and_return(twilio_client)
  end

  describe "#send_sms" do
    let(:recipient_phone_number) { '8585858585' }
    let(:expected_sms_recipient_phone_number) { '+918585858585' }

    it "correctly calls the Twilio API" do
      expect(twilio_client).to receive_message_chain('messages.create').with(
        from: sender_phone_number,
        to: expected_sms_recipient_phone_number,
        status_callback: fake_callback_url,
        body: "test sms message"
      )

      notification_service.send_sms(recipient_phone_number, "test sms message", fake_callback_url)
    end
  end

  describe "#send_whatsapp" do
    let(:recipient_phone_number) { '8182838485' }
    let(:expected_sms_recipient_phone_number) { '+918182838485' }

    it "correctly calls the Twilio API" do
      expect(twilio_client).to receive_message_chain('messages.create').with(
        from: "whatsapp:#{sender_phone_number}",
        to: "whatsapp:#{expected_sms_recipient_phone_number}",
        status_callback: fake_callback_url,
        body: "test whatsapp message"
      )

      notification_service.send_whatsapp(recipient_phone_number, "test whatsapp message", fake_callback_url)
    end
  end

  describe "#parse_phone_number" do
    before do
      @original_country = Rails.application.config.country
      Rails.application.config.country = { sms_country_code: '+880' }
    end

    after do
      Rails.application.config.country = @original_country
    end

    it "adds the correct country code" do
      expect(notification_service.parse_phone_number("98765 43210")).to eq("+8809876543210")
    end
  end
end
