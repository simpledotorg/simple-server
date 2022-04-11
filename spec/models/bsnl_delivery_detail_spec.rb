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

  describe ".in_progress?" do
    it "returns true if the notification is in the process of being delivered" do
      new_detail = create(:bsnl_delivery_detail, message_status: nil)
      created_detail = create(:bsnl_delivery_detail, message_status: "0")
      input_error_detail = create(:bsnl_delivery_detail, message_status: "1")
      inserted_in_queue_detail = create(:bsnl_delivery_detail, message_status: "2")
      submitted_to_smsc_detail = create(:bsnl_delivery_detail, message_status: "3")
      rejected_by_smsc_detail = create(:bsnl_delivery_detail, message_status: "4")
      accepted_by_carrier_detail = create(:bsnl_delivery_detail, message_status: "5")
      delivery_failed_detail = create(:bsnl_delivery_detail, message_status: "6")
      delivered_detail = create(:bsnl_delivery_detail, message_status: "7")

      expect(new_detail.in_progress?).to be_truthy
      expect(created_detail.in_progress?).to be_truthy
      expect(input_error_detail.in_progress?).not_to be_truthy
      expect(inserted_in_queue_detail.in_progress?).to be_truthy
      expect(submitted_to_smsc_detail.in_progress?).to be_truthy
      expect(rejected_by_smsc_detail.in_progress?).not_to be_truthy
      expect(accepted_by_carrier_detail.in_progress?).to be_truthy
      expect(delivery_failed_detail.in_progress?).not_to be_truthy
      expect(delivered_detail.in_progress?).not_to be_truthy
    end
  end

  describe ".unsuccessful?" do
    it "returns true if the notification could not be delivered" do
      new_detail = create(:bsnl_delivery_detail, message_status: nil)
      created_detail = create(:bsnl_delivery_detail, message_status: "0")
      input_error_detail = create(:bsnl_delivery_detail, message_status: "1")
      inserted_in_queue_detail = create(:bsnl_delivery_detail, message_status: "2")
      submitted_to_smsc_detail = create(:bsnl_delivery_detail, message_status: "3")
      rejected_by_smsc_detail = create(:bsnl_delivery_detail, message_status: "4")
      accepted_by_carrier_detail = create(:bsnl_delivery_detail, message_status: "5")
      delivery_failed_detail = create(:bsnl_delivery_detail, message_status: "6")
      delivered_detail = create(:bsnl_delivery_detail, message_status: "7")

      expect(new_detail.unsuccessful?).not_to be_truthy
      expect(created_detail.unsuccessful?).not_to be_truthy
      expect(input_error_detail.unsuccessful?).to be_truthy
      expect(inserted_in_queue_detail.unsuccessful?).not_to be_truthy
      expect(submitted_to_smsc_detail.unsuccessful?).not_to be_truthy
      expect(rejected_by_smsc_detail.unsuccessful?).to be_truthy
      expect(accepted_by_carrier_detail.unsuccessful?).not_to be_truthy
      expect(delivery_failed_detail.unsuccessful?).to be_truthy
      expect(delivered_detail.unsuccessful?).not_to be_truthy
    end
  end

  describe ".successful?" do
    it "returns true if the notification was delivered successfully" do
      new_detail = create(:bsnl_delivery_detail, message_status: nil)
      created_detail = create(:bsnl_delivery_detail, message_status: "0")
      input_error_detail = create(:bsnl_delivery_detail, message_status: "1")
      inserted_in_queue_detail = create(:bsnl_delivery_detail, message_status: "2")
      submitted_to_smsc_detail = create(:bsnl_delivery_detail, message_status: "3")
      rejected_by_smsc_detail = create(:bsnl_delivery_detail, message_status: "4")
      accepted_by_carrier_detail = create(:bsnl_delivery_detail, message_status: "5")
      delivery_failed_detail = create(:bsnl_delivery_detail, message_status: "6")
      delivered_detail = create(:bsnl_delivery_detail, message_status: "7")

      expect(new_detail.successful?).not_to be_truthy
      expect(created_detail.successful?).not_to be_truthy
      expect(input_error_detail.successful?).not_to be_truthy
      expect(inserted_in_queue_detail.successful?).not_to be_truthy
      expect(submitted_to_smsc_detail.successful?).not_to be_truthy
      expect(rejected_by_smsc_detail.successful?).not_to be_truthy
      expect(accepted_by_carrier_detail.successful?).not_to be_truthy
      expect(delivery_failed_detail.successful?).not_to be_truthy
      expect(delivered_detail.successful?).to be_truthy
    end
  end
end
