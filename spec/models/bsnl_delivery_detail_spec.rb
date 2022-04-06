require "rails_helper"

RSpec.describe BsnlDeliveryDetail, type: :model do
  describe "Associations" do
    it { is_expected.to have_one(:communication) }
  end

  describe ".in_progress" do
    it "returns deliverables which are in progress" do
      in_progress_status_codes = %w[0 2 3 5]
      in_progress_details = in_progress_status_codes.map do |status_code|
        create(:bsnl_delivery_detail, message_status: status_code)
      end

      delivered_detail = create(:bsnl_delivery_detail, message_status: "7")

      expect(described_class.in_progress).to match_array(in_progress_details)
      expect(described_class.in_progress).not_to include(delivered_detail)
    end

    it "returns deliverables if they don't have a message status set" do
      detail = create(:bsnl_delivery_detail, message_status: nil)
      delivered_detail = create(:bsnl_delivery_detail, message_status: "7")
      expect(described_class.in_progress).to include(detail)
      expect(described_class.in_progress).not_to include(delivered_detail)
    end
  end

  describe ".create_with_communication!" do
    it "creates a communication with a BsnlDeliveryDetail" do
      phone_number = Faker::PhoneNumber.phone_number
      communication =
        described_class.create_with_communication!(
          message_id: "1000123",
          recipient_number: phone_number,
          dlt_template_id: "12398127312492"
        )

      expect(communication.detailable.recipient_number).to eq phone_number
    end
  end
end
