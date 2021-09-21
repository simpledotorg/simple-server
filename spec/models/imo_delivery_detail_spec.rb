require "rails_helper"

describe ImoDeliveryDetail, type: :model do
  subject(:imo_delivery_detail) { create(:imo_delivery_detail) }

  describe "associations" do
    it { should have_one(:communication) }
  end

  describe "validations" do
    it { should validate_presence_of(:result) }
    it { should validate_presence_of(:callee_phone_number) }
  end

  describe "#unsucessful?" do
    it "is true if result is error, no_imo_account, or not_subscribed" do
      subject.update!(result: :sent)
      expect(subject.unsuccessful?).to be_falsey
      subject.update!(result: :no_imo_account)
      expect(subject.unsuccessful?).to be_truthy
      subject.update!(result: :not_subscribed)
      expect(subject.unsuccessful?).to be_truthy
      subject.update!(result: :read)
      expect(subject.unsuccessful?).to be_falsey
      subject.update!(result: :error)
      expect(subject.unsuccessful?).to be_truthy
    end
  end

  describe "#sucessful?" do
    it "is true if result is read" do
      subject.update!(result: :sent)
      expect(subject.successful?).to be_falsey
      subject.update!(result: :no_imo_account)
      expect(subject.successful?).to be_falsey
      subject.update!(result: :not_subscribed)
      expect(subject.successful?).to be_falsey
      subject.update!(result: :read)
      expect(subject.successful?).to be_truthy
      subject.update!(result: :error)
      expect(subject.successful?).to be_falsey
    end
  end

  describe "#in_progress?" do
    it "is true if result is sent" do
      subject.update!(result: :sent)
      expect(subject.in_progress?).to be_truthy
      subject.update!(result: :no_imo_account)
      expect(subject.in_progress?).to be_falsey
      subject.update!(result: :not_subscribed)
      expect(subject.in_progress?).to be_falsey
      subject.update!(result: :read)
      expect(subject.in_progress?).to be_falsey
      subject.update!(result: :error)
      expect(subject.in_progress?).to be_falsey
    end
  end
end
