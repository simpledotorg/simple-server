require "rails_helper"

RSpec.describe BsnlDeliveryDetail, type: :model do
  describe "Associations" do
    it { is_expected.to have_one(:communication) }
  end

  describe ".create_with_communication!" do
    it "creates a communication with a BsnlDeliveryDetail" do
      phone_number = "1111111111"
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
