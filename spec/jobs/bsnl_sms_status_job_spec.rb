require "rails_helper"

RSpec.describe BsnlSmsStatusJob, type: :job do
  describe "#perform" do
    it "raises an error if a detailable with the message ID doesn't exist" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("BSNL_IHCI_HEADER").and_return("ABCDEF")
      allow(ENV).to receive(:[]).with("BSNL_IHCI_ENTITY_ID").and_return("123")
      Configuration.create(name: "bsnl_sms_jwt", value: "a jwt token")

      described_class.perform_async("non-existent-message-id")
      expect { described_class.drain }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "calls the BSNL API and updates the status in the delivery detail" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("BSNL_IHCI_HEADER").and_return("ABCDEF")
      allow(ENV).to receive(:[]).with("BSNL_IHCI_ENTITY_ID").and_return("123")
      Configuration.create(name: "bsnl_sms_jwt", value: "a jwt token")

      message_id = "12345"
      detailable = create(:bsnl_delivery_detail, message_id: message_id)
      allow_any_instance_of(Messaging::Bsnl::Api).to receive(:get_message_status_report).and_return(
        {"Message_Status" => "7",
         "Message" => "A test message",
         "Message_Status_Description" => "Message Delivered",
         "Delivery_Success_Time" => "03-04-2022 06:00:00 PM"}
      )

      described_class.perform_async(message_id)
      described_class.drain
      detailable.reload

      expect(detailable.message_status).to eq("delivered")
      expect(detailable.message).to eq("A test message")
      expect(detailable.result).to eq("Message Delivered")
      expect(detailable.delivered_on).to eq("Sun, 03 Apr 2022 12:30:00")
    end

    it "raises exceptions if there's an error in fetching the status" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("BSNL_IHCI_HEADER").and_return("ABCDEF")
      allow(ENV).to receive(:[]).with("BSNL_IHCI_ENTITY_ID").and_return("123")
      Configuration.create(name: "bsnl_sms_jwt", value: "a jwt token")

      message_id = "12345"
      create(:bsnl_delivery_detail, message_id: message_id)
      allow_any_instance_of(Messaging::Bsnl::Api).to receive(:get_message_status_report).and_return(
        {"Error" => "Error description"}
      )

      described_class.perform_async(message_id)
      expect { described_class.drain }.to raise_error(Messaging::Bsnl::FetchStatusError)
    end
  end
end
