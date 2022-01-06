# frozen_string_literal: true

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
    it "is true if result is no_imo_account or not_subscribed" do
      subject.sent!
      expect(subject.unsuccessful?).to be_falsey
      subject.no_imo_account!
      expect(subject.unsuccessful?).to be_truthy
      subject.not_subscribed!
      expect(subject.unsuccessful?).to be_truthy
      subject.read!
      expect(subject.unsuccessful?).to be_falsey
    end
  end

  describe "#sucessful?" do
    it "is true if result is read" do
      subject.sent!
      expect(subject.successful?).to be_falsey
      subject.no_imo_account!
      expect(subject.successful?).to be_falsey
      subject.not_subscribed!
      expect(subject.successful?).to be_falsey
      subject.read!
      expect(subject.successful?).to be_truthy
    end
  end

  describe "#in_progress?" do
    it "is true if result is sent" do
      subject.sent!
      expect(subject.in_progress?).to be_truthy
      subject.no_imo_account!
      expect(subject.in_progress?).to be_falsey
      subject.not_subscribed!
      expect(subject.in_progress?).to be_falsey
      subject.read!
      expect(subject.in_progress?).to be_falsey
    end
  end

  describe "#unsubscribed_or_missing?" do
    it "returns true for no_imo_account and not_subscribed" do
      subject.sent!
      expect(subject.unsubscribed_or_missing?).to be_falsey
      subject.no_imo_account!
      expect(subject.unsubscribed_or_missing?).to be_truthy
      subject.not_subscribed!
      expect(subject.unsubscribed_or_missing?).to be_truthy
      subject.read!
      expect(subject.unsubscribed_or_missing?).to be_falsey
    end
  end
end
