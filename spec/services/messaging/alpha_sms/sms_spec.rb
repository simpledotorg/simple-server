require "rails_helper"

RSpec.describe Messaging::AlphaSms::Sms do
  describe "#send_message" do
    it "passes sanitised variable content to the API" do
      mock_api = double("AlphaSmsApiDouble")
      allow(Messaging::AlphaSms::Api).to receive(:new).and_return(mock_api)
      allow(mock_api).to receive(:send_sms)
      allow(mock_api).to receive(:send_sms).and_return({"error" => 0,
                                                        "msg" => "Request successfully submitted",
                                                        "data" => {"request_id" => 1111111}})

      expect(mock_api).to receive(:send_sms).with(
        recipient_number: "+880123123",
        message: "Test message"
      )

      described_class.send_message(
        recipient_number: "+880123123",
        message: "Test message"
      )
    end

    it "raises any errors received from the API as an exception" do
      mock_api = double("AlphaSmsApiDouble")
      allow(Messaging::AlphaSms::Api).to receive(:new).and_return(mock_api)
      allow(mock_api).to receive(:send_sms)
      allow(mock_api).to receive(:send_sms).and_return({"error" => 416,
                                                        "msg" => "No valid number found"})

      expect {
        described_class.send_message(
          recipient_number: "+880123123",
          message: "Test message"
        )
      }.to raise_error(Messaging::AlphaSms::Error).with_message("Error while calling Alpha SMS API: No valid number found")
    end

    it "creates a detailable and a communication and returns it" do
      mock_api = double("AlphaSmsApiDouble")
      allow(Messaging::AlphaSms::Api).to receive(:new).and_return(mock_api)
      allow(mock_api).to receive(:send_sms)
      allow(mock_api).to receive(:send_sms).and_return({"error" => 0,
                                                        "msg" => "Request successfully submitted",
                                                        "data" => {"request_id" => 1111111}})

      communication = described_class.send_message(recipient_number: "+880123123", message: "Test message")
      expect(communication.detailable.request_id).to eq("1111111")
    end

    it "calls the block passed to it with the communication created" do
      mock_api = double("AlphaSmsApiDouble")
      allow(Messaging::AlphaSms::Api).to receive(:new).and_return(mock_api)
      allow(mock_api).to receive(:send_sms)
      allow(mock_api).to receive(:send_sms).and_return({"error" => 0,
                                                        "msg" => "Request successfully submitted",
                                                        "data" => {"request_id" => 1111111}})
      spy = spy("Awaits a_method to be called")

      described_class.send_message(recipient_number: "+880123123", message: "Test message") { |_|
        spy.a_method
      }
      expect(spy).to have_received(:a_method)
    end
  end
end
