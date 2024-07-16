require "rails_helper"

RSpec.describe Messaging::Mobitel::Api do
  def stub_credentials(*keys)
    env_variables = {
      alias: "MOBITEL_SMS_ALIAS",
      username: "MOBITEL_API_USERNAME",
      password: "MOBITEL_API_PASSWORD"
    }
    allow(ENV).to receive(:[]).and_call_original
    keys.each do |key|
      allow(ENV).to receive(:[]).with(env_variables[key]).and_return("TEST")
    end
  end

  describe "#new" do
    it "does not raise any errors when all the ENV variables are present" do
      stub_credentials(:username, :password, :alias)
      expect { described_class.new }.not_to raise_error
    end

    it "raises an error if SMS Alias is missing" do
      stub_credentials(:username, :password)
      expect { described_class.new }.to raise_error(Messaging::Mobitel::Error).with_message("Error while calling Mobitel API: Missing Mobitel SMS Alias")
    end

    it "raises an error if username is missing" do
      stub_credentials(:password, :alias)
      expect { described_class.new }.to raise_error(Messaging::Mobitel::Error).with_message("Error while calling Mobitel API: Missing Mobitel username")
    end

    it "raises an error if password is missing" do
      stub_credentials(:username, :alias)
      expect { described_class.new }.to raise_error(Messaging::Mobitel::Error).with_message("Error while calling Mobitel API: Missing Mobitel password")
    end
  end

  describe "#send_message" do
    it "makes an API call" do
      stub_credentials(:username, :password, :alias)
      message = "Test Message"
      recipient_number = Faker::PhoneNumber.phone_number

      request = stub_request(:get, "https://msmsenterpriseapi.mobitel.lk/EnterpriseSMSV3/esmsproxy_multilang.php")
        .with(query: hash_including({}))
        .to_return(body: "200")
      described_class.new.send_sms(recipient_number: recipient_number, message: message)
      expect(request).to have_been_made
    end

    it "raises an exception if non 200 resopnse is received" do
      stub_credentials(:username, :password, :alias)
      message = "Test Message"
      recipient_number = Faker::PhoneNumber.phone_number

      stub_request(:get, "https://msmsenterpriseapi.mobitel.lk/EnterpriseSMSV3/esmsproxy_multilang.php")
        .with(query: hash_including({}))
        .to_return(body: "Not found")

      expect {
        described_class.new.send_sms(recipient_number: recipient_number, message: message)
      }.to raise_error(Messaging::Mobitel::Error).with_message("Error while calling Mobitel API: Non standard response received for Mobitel API: Not found")
    end
  end
end
