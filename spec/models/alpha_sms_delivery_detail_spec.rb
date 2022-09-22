require "rails_helper"

RSpec.describe AlphaSmsDeliveryDetail, type: :model do
  describe "Associations" do
    it { is_expected.to have_one(:communication) }
  end

  describe "#in_progress?" do
    it "is always false because messages are reported as either success or failures" do
      expect(described_class.new.in_progress?).to be false
    end

    describe "#unsuccessful?" do
      it "returns true if the notification could not be delivered" do
        delivered_detail = create(:alpha_sms_delivery_detail, request_status: "Sent")
        undelivered_detail = create(:alpha_sms_delivery_detail, request_status: "Failed")

        expect(delivered_detail.unsuccessful?).to be false
        expect(undelivered_detail.unsuccessful?).to be true
      end
    end
  end

  describe "#successful?" do
    it "returns true if the notification could not be delivered" do
      delivered_detail = create(:alpha_sms_delivery_detail, request_status: "Sent")
      undelivered_detail = create(:alpha_sms_delivery_detail, request_status: "Failed")

      expect(delivered_detail.unsuccessful?).to be false
      expect(undelivered_detail.unsuccessful?).to be true
    end
  end

  describe ".create_with_communication!" do
    it "creates a communication with a delivery detail" do
      phone_number = Faker::PhoneNumber.phone_number
      message = "Test Message"
      request_id = "1950547"
      communication =
        described_class.create_with_communication!(
          request_id: request_id,
          recipient_number: phone_number,
          message: message
        )

      expect(communication.detailable.recipient_number).to eq phone_number
      expect(communication.detailable.message).to eq message
      expect(communication.detailable.request_id).to eq request_id
    end
  end
end
