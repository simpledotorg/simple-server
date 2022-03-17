require "rails_helper"

RSpec.describe Messaging::Twilio::Api do
  def stub_twilio_client
    client = double("TwilioClientDouble")
    allow(Twilio::REST::Client).to receive(:new).and_return(client)
    allow(client).to receive_message_chain("messages.create")
  end

  before do
    allow(described_class).to receive(:communication_type).and_return("sms")
    allow_any_instance_of(described_class).to receive(:sender_number).and_return("9999999999")
  end

  describe "test mode vs production mode" do
    it "uses the test twilio creds by default in test environment" do
      twilio_test_account_sid = ENV.fetch("TWILIO_TEST_ACCOUNT_SID")
      twilio_test_auth_token = ENV.fetch("TWILIO_TEST_AUTH_TOKEN")
      stub_twilio_client

      expect(Twilio::REST::Client).to receive(:new).with(twilio_test_account_sid, twilio_test_auth_token)

      described_class.send_message(recipient_number: "9999999999", message: "hello")
    end

    it "uses the production twilio creds when SIMPLE_SERVER_ENV is production" do
      stub_const("SIMPLE_SERVER_ENV", "production")
      twilio_account_sid = ENV.fetch("TWILIO_ACCOUNT_SID")
      twilio_auth_token = ENV.fetch("TWILIO_AUTH_TOKEN")
      stub_twilio_client

      expect(Twilio::REST::Client).to receive(:new).with(twilio_account_sid, twilio_auth_token)

      described_class.send_message(recipient_number: "9999999999", message: "hello")
    end

    it "uses the production twilio creds when TWILIO_PRODUCTION_OVERRIDE is set" do
      stub_const("SIMPLE_SERVER_ENV", "sandbox")
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("TWILIO_PRODUCTION_OVERRIDE").and_return("true")
      twilio_account_sid = ENV.fetch("TWILIO_ACCOUNT_SID")
      twilio_auth_token = ENV.fetch("TWILIO_AUTH_TOKEN")
      stub_twilio_client

      expect(Twilio::REST::Client).to receive(:new).with(twilio_account_sid, twilio_auth_token)

      described_class.send_message(recipient_number: "9999999999", message: "hello")
    end
  end

  it "raises a custom error on twilio error" do
    recipient_phone_number = "+918585858585"
    client = double("TwilioClientDouble")
    allow(Twilio::REST::Client).to receive(:new).and_return(client)
    response = double
    allow(response).to receive(:body).and_return({})
    allow(response).to receive(:status_code).and_return(200)

    allow(client).to receive_message_chain("messages.create").and_raise(Twilio::REST::RestError.new("An error", response))
    expect {
      described_class.send_message(
        recipient_number: recipient_phone_number,
        message: "test message"
      )
    }.to raise_error(Messaging::Twilio::Error)
  end

  it "raises an error with a nil reason if the twilio error is not in our list" do
    recipient_phone_number = "+918585858585"
    client = double("TwilioClientDouble")
    allow(Twilio::REST::Client).to receive(:new).and_return(client)
    response = double
    allow(response).to receive(:body).and_return({"code" => 20000})
    allow(response).to receive(:status_code).and_return(200) # this is just to stub the exception, it breaks otherwise

    allow(client).to receive_message_chain("messages.create").and_raise(
      Twilio::REST::RestError.new("An error", response)
    )

    expect {
      described_class.send_message(
        recipient_number: recipient_phone_number,
        message: "test message"
      )
    }.to raise_error(an_instance_of(Messaging::Twilio::Error)) do |error|
      expect(error.reason).to be_nil
    end
  end
end
