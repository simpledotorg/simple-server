require "rails_helper"

RSpec.describe Messaging::Mobitel::Sms do
  describe "#send_message" do
    it "passes sanitised variable content to the API" do
      mock_api = double("MobitelApiDouble")
      allow(Messaging::Mobitel::Api).to receive(:new).and_return(mock_api)
      allow(mock_api).to receive(:send_sms)
      allow(mock_api).to receive(:send_sms).and_return(200)

      expect(mock_api).to receive(:send_sms).with(
        recipient_number: "+11001100",
        message: "Test message"
      )

      described_class.send_message(
        recipient_number: "+11001100",
        message: "Test message"
      )
    end

    it "raises any response whose body is non 200 as exception" do
      mock_api = double("MobitelApiDouble")
      allow(Messaging::Mobitel::Api).to receive(:new).and_return(mock_api)
      allow(mock_api).to receive(:send_sms)
      allow(mock_api).to receive(:send_sms).and_return(159)

      expect(mock_api).to receive(:send_sms).with(
        recipient_number: "+11001100",
        message: "Test message"
      )

      expect {
        described_class.send_message(
          recipient_number: "+11001100",
          message: "Test message"
        )
      }.to raise_error(Messaging::Mobitel::Error)
    end
  end
end
