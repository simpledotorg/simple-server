require "rails_helper"

RSpec.describe VoiceCallDetail, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:call_request_id) }

    it "requires a unique call_request_id" do
      existing = create(:voice_call_detail)
      expect(build(:voice_call_detail, call_request_id: existing.call_request_id)).not_to be_valid
    end
  end

  describe "delivery states" do
    it "is in progress until the voice agent reports back" do
      detail = build(:voice_call_detail, status: "requested")

      expect(detail).to be_in_progress
      expect(detail).not_to be_successful
      expect(detail).not_to be_unsuccessful
    end

    it "is successful when the call completed" do
      detail = build(:voice_call_detail, status: "completed")

      expect(detail).to be_successful
      expect(detail).not_to be_in_progress
    end

    %w[unreached expired failed].each do |status|
      it "is unsuccessful when the call was #{status}" do
        detail = build(:voice_call_detail, status: status)

        expect(detail).to be_unsuccessful
        expect(detail).not_to be_in_progress
      end
    end
  end

  describe ".create_with_communication!" do
    it "creates a voice call detail with an ai_voice_call communication" do
      communication = described_class.create_with_communication!(call_request_id: "abc-123")

      expect(communication).to be_persisted
      expect(communication.communication_type).to eq("ai_voice_call")
      expect(communication.detailable.call_request_id).to eq("abc-123")
      expect(communication.detailable).to be_status_requested
    end
  end

  describe "#appointment" do
    it "returns the appointment the call was requested for" do
      detail = create(:voice_call_detail, :with_communication)

      expect(detail.appointment).to eq(detail.communication.notification.subject)
    end
  end

  describe ".pending_review" do
    it "returns confident, unresolved removal suggestions" do
      pending = create(:voice_call_detail, status: "completed", outcome: "removal_suggested",
        suggested_remove_reason: "moved", confidence: "high")
      create(:voice_call_detail, status: "completed", outcome: "removal_suggested",
        suggested_remove_reason: "moved", confidence: "high", resolved_at: Time.current)
      create(:voice_call_detail, status: "completed", outcome: "removal_suggested",
        suggested_remove_reason: "moved", confidence: "low")
      create(:voice_call_detail, status: "completed", outcome: "agreed_to_visit", confidence: "high")

      expect(described_class.pending_review).to contain_exactly(pending)
    end
  end
end
