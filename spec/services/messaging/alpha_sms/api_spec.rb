require "rails_helper"

RSpec.describe Messaging::AlphaSms::Api do
  def stub_credentials
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("ALPHA_SMS_API_KEY").and_return("ABCDEF")
    allow(ENV).to receive(:[]).with("ALPHA_SMS_SENDER_ID").and_return("AAAAAA")
  end

  describe "#new" do
    it "raises an error if configuration is missing" do
      expect { described_class.new }.to raise_error(Messaging::AlphaSms::Error).with_message("Error while calling Alpha SMS API: Missing Alpha SMS credentials")
    end
  end

  describe "#send_sms" do
    it "makes an API call" do
      stub_credentials
      message = "Test message"
      recipient_number = "+8801885374409"

      request = stub_request(:post, "https://api.sms.net.bd/sendsms")
      described_class.new.send_sms(recipient_number: recipient_number, message: message)
      expect(request.with(body: {
        api_key: "ABCDEF",
        msg: message,
        to: recipient_number,
        sender_id: "AAAAAA"
      })).to have_been_made
    end

    it "raises an exception if the API sends a non-200 response" do
      stub_credentials

      stub_request(:post, "https://api.sms.net.bd/sendsms").to_return(status: 401, body: "a response")
      expect {
        described_class.new.send_sms(recipient_number: "+8801885374409", message: "Test message")
      }.to raise_error(Messaging::AlphaSms::Error).with_message("Error while calling Alpha SMS API: API returned 401 with a response")
    end
  end

  describe "#get_message_status_report" do
    it "gets the status for a message" do
      request_id = 123456
      stub_credentials

      stub_request(:post, "https://api.sms.net.bd/report/request/#{request_id}").to_return(body: {a: :hash}.to_json)
      expect(described_class.new.get_message_status_report(request_id)).to eq({"a" => "hash"})
    end
  end

  describe "#get_account_balance" do
    it "gets the account's balance" do
      stub_credentials

      stub_request(:post, "https://api.sms.net.bd/user/balance").to_return(body: {a: :hash}.to_json)
      expect(described_class.new.get_account_balance).to eq({"a" => "hash"})
    end
  end
end
