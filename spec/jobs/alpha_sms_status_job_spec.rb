require "rails_helper"

RSpec.describe AlphaSmsStatusJob, type: :job do
  describe "#perform" do
    it "raises an error if a detailable with the message ID doesn't exist" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("ALPHA_SMS_API_KEY").and_return("ABCDEF")
      stub_request(:post, "https://api.sms.net.bd//report/request/non-existent-message-id")

      described_class.perform_async("non-existent-message-id")
      expect { described_class.drain }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "calls the Alpha SMS API and updates the status in the delivery detail" do
      request_id = 12345
      detailable = create(:alpha_sms_delivery_detail, request_id: request_id)
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("ALPHA_SMS_API_KEY").and_return("ABCDEF")
      stub_request(:post, "https://api.sms.net.bd/report/request/#{request_id}")
        .to_return(body: {
          "error" => 0,
          "msg" => "Success",
          "data" => {
            "request_id" => request_id,
            "request_status" => "Complete",
            "request_charge" => "0.5400",
            "recipients" => [
              {
                "number" => "111111111",
                "charge" => "0.5400",
                "status" => "Sent"
              }
            ]
          }
        }.to_json)

      described_class.perform_async(request_id)
      described_class.drain
      expect(detailable.reload)
      expect(detailable.request_status).to eq("Sent")
    end

    it "raises exceptions if there's an error in fetching the status" do
      request_id = "12345"
      create(:alpha_sms_delivery_detail, request_id: request_id)
      allow_any_instance_of(Messaging::AlphaSms::Api).to receive(:get_message_status_report).and_return(
        {"error" => "an-error"}
      )

      described_class.perform_async(request_id)
      expect { described_class.drain }.to raise_error(Messaging::AlphaSms::Error)
    end
  end
end
