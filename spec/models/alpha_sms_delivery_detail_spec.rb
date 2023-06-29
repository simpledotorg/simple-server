require "rails_helper"

RSpec.describe AlphaSmsDeliveryDetail, type: :model do
  describe "Associations" do
    it { is_expected.to have_one(:communication) }
  end

  describe ".in_progress" do
    it "returns detailables where request_status is not set" do
      in_progress_detailable = create(:alpha_sms_delivery_detail, request_status: nil)
      _delivered_detail = create(:alpha_sms_delivery_detail, request_status: "Sent")

      expect(described_class.in_progress).to contain_exactly(in_progress_detailable)
    end
  end

  describe "#in_progress?" do
    it "is true when request_status is not set" do
      in_progress_detailable = create(:alpha_sms_delivery_detail, request_status: nil)
      delivered_detail = create(:alpha_sms_delivery_detail, request_status: "Sent")

      expect(in_progress_detailable.in_progress?).to be true
      expect(delivered_detail.in_progress?).to be false
    end
  end

  describe "#unsuccessful?" do
    it "returns true if the notification could not be delivered" do
      delivered_detail = create(:alpha_sms_delivery_detail, request_status: "Sent")
      undelivered_detail = create(:alpha_sms_delivery_detail, request_status: "Failed")

      expect(delivered_detail.unsuccessful?).to be false
      expect(undelivered_detail.unsuccessful?).to be true
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
        ).tap do |c|
          c.detailable.request_status = "Sent"
        end

      expect(communication.detailable.recipient_number).to eq phone_number
      expect(communication.detailable.message).to eq message
      expect(communication.detailable.request_id).to eq request_id
      expect(communication.detailable.result).to eq "Sent"
    end
  end
end
