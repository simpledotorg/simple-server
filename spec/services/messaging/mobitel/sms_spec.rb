require "rails_helper"

RSpec.describe Messaging::Mobitel::Sms do
  describe "#send_message" do
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

    it "creates a detailable and a communication and returns it" do
      phone_number = Faker::PhoneNumber.phone_number
      mock_api = double("MobitelApiDouble")
      allow(Messaging::Mobitel::Api).to receive(:new).and_return(mock_api)
      allow(mock_api).to receive(:send_sms)
      allow(mock_api).to receive(:send_sms).and_return(200)

      communication = described_class.send_message(
        recipient_number: phone_number,
        message: "Test message"
      )

      expect(communication.detailable.recipient_number).to eq(phone_number)
    end

    it "yields with a Communication instance when send_message is called" do
      mock_api = double("MobitelApiDouble")
      allow(Messaging::Mobitel::Api).to receive(:new).and_return(mock_api)
      allow(mock_api).to receive(:send_sms)
      allow(mock_api).to receive(:send_sms).and_return(200)

      expect { |b|
        described_class.send_message(
          recipient_number: "+110011001", message: "Test message", &b
        )
      }.to yield_with_args(instance_of(Communication))
    end
  end
end
