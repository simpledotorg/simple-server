require "rails_helper"

describe ImoDeliveryDetail, type: :model do
  subject(:imo_delivery_detail) { create(:imo_delivery_detail) }

  describe "Associations" do
    it { should have_one(:communication) }
  end

  describe "#update_authorization" do
    let(:patient) { create(:patient) }
    let(:imo_authorization) { create(:imo_authorization, status: "subscribed", patient: patient) }
    let(:notification) { create(:notification, patient: patient) }
    let(:communication) { create(:communication, notification: notification, detailable: subject) }

    before { patient.imo_authorization = imo_authorization }

    it "updates the patient's imo authorization when creating a detail of result 'no_imo_account'" do
      expect {
        create(:imo_delivery_detail, result: :no_imo_account, communication: communication)
      }.to change { patient.imo_authorization.reload.status }.from("subscribed").to("no_imo_account")
    end

    it "updates the patient's imo authorization when creating a detail of result 'not_subscribed'" do
      expect {
        create(:imo_delivery_detail, result: :not_subscribed, communication: communication)
      }.to change { patient.imo_authorization.reload.status }.from("subscribed").to("not_subscribed")
    end

    it "does not update the patient's imo authorization when creating a detail with other result types" do
      expect {
        create(:imo_delivery_detail, result: :sent, communication: communication)
        create(:imo_delivery_detail, result: :read, communication: communication)
        create(:imo_delivery_detail, result: :error, communication: communication)
      }.not_to change { patient.imo_authorization.reload }
    end
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
