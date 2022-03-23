require "rails_helper"

describe TwilioSmsDeliveryDetail, type: :model do
  subject(:twilio_sms_delivery_detail) { create(:twilio_sms_delivery_detail) }

  describe "Associations" do
    it { should have_one(:communication) }
  end

  describe ".create_with_communication!" do
    it "creates a communication with a TwilioSmsDeliveryDetail" do
      expect {
        described_class.create_with_communication!(callee_phone_number: "1111111111",
          session_id: SecureRandom.uuid,
          result: "sent",
          communication_type: :sms)
      }.to change { Communication.count }.by(1)
        .and change { TwilioSmsDeliveryDetail.count }.by(1)
    end
  end
end
