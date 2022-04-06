require "rails_helper"

describe TwilioSmsDeliveryDetail, type: :model do
  subject(:twilio_sms_delivery_detail) { create(:twilio_sms_delivery_detail) }

  describe "Associations" do
    it { should have_one(:communication) }
  end

  describe ".create_with_communication!" do
    it "creates a communication with a TwilioSmsDeliveryDetail" do
      phone_number = Faker::PhoneNumber.phone_number
      communication =
        described_class.create_with_communication!(
          callee_phone_number: phone_number,
          session_id: SecureRandom.uuid,
          result: "sent",
          communication_type: :sms
        )

      expect(communication.detailable.callee_phone_number).to eq phone_number
    end
  end
end
