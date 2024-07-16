require "rails_helper"

RSpec.describe MobitelDeliveryDetail, type: :model do
  describe "Associations" do
    it { is_expected.to have_one(:communication) }
  end

  describe "#in_progress?" do
    it "is always false because messages are either successful or fails at API validation" do
      expect(described_class.new.in_progress?).to be false
    end
  end

  describe "#unsuccessful?" do
    it "is always false because messages are either successful or fails at API validation" do
      expect(described_class.new.unsuccessful?).to be false
    end
  end

  describe "#successful?" do
    it "is always false because messages are either successful or fails at API validation" do
      expect(described_class.new.successful?).to be true
    end
  end

  describe ".create_with_communication!" do
    it "creates a communication channel with delivery details" do
      phone_number = Faker::PhoneNumber.phone_number
      message = "Test Message"
      communication = described_class.create_with_communication!(
        recipient_number: phone_number,
        message: message
      )

      expect(communication.detailable.recipient_number).to eq phone_number
      expect(communication.detailable.message).to eq message
    end
  end
end
