require "rails_helper"

RSpec.describe Messaging::VoiceAgent::Call do
  let(:appointment) { create(:appointment, scheduled_date: 10.days.ago) }
  let(:notification) do
    create(:notification,
      subject: appointment,
      patient: appointment.patient,
      purpose: "overdue_voice_call",
      status: "scheduled")
  end
  let(:mock_api) { instance_double(Messaging::VoiceAgent::Api, create_call: nil) }

  before { allow(Messaging::VoiceAgent::Api).to receive(:new).and_return(mock_api) }

  it "uses the ai_voice_call communication type" do
    expect(described_class.communication_type).to eq("ai_voice_call")
  end

  describe "#send_message" do
    it "sends the call request built from the notification" do
      expected_payload = VoiceAgent::CallRequest.new(notification).payload

      described_class.send_message(notification: notification)

      expect(mock_api).to have_received(:create_call).with(expected_payload)
    end

    it "creates a voice call detail and communication keyed by the call request id" do
      communication = described_class.send_message(notification: notification)

      expect(communication.communication_type).to eq("ai_voice_call")
      expect(communication.detailable.call_request_id).to eq(VoiceAgent::CallRequest.new(notification).call_request_id)
      expect(communication.detailable).to be_status_requested
    end

    it "calls the block with the communication inside the same transaction" do
      communication = described_class.send_message(notification: notification) { |c| notification.record_communication(c) }

      expect(communication.reload.notification).to eq(notification)
      expect(notification.reload).to be_status_sent
    end

    it "does not create a communication when the voice agent rejects the request" do
      allow(mock_api).to receive(:create_call).and_raise(Messaging::VoiceAgent::Error.new("boom"))

      expect { described_class.send_message(notification: notification) }
        .to raise_error(Messaging::VoiceAgent::Error)
        .and change(Communication, :count).by(0)
    end
  end
end
