require "rails_helper"

RSpec.describe AppointmentNotification::Worker, type: :job do
  describe "#perform" do
    before do
      Flipper.enable(:notifications)
      allow(Statsd.instance).to receive(:increment).with(anything)
    end

    let(:notification) {
      create(:notification,
        subject: create(:appointment),
        status: "scheduled",
        message: "locale.key")
    }

    def mock_successful_delivery
      response_double = double("NotificationServiceResponse")
      twilio_client = double("TwilioClientDouble")

      allow(Twilio::REST::Client).to receive(:new).and_return(twilio_client)
      allow(twilio_client).to receive_message_chain("messages.create").and_return(response_double)
    end

    it "logs but creates nothing when notifications and experiment flags are disabled" do
      Flipper.disable(:notifications)
      Flipper.disable(:experiment)

      expect(Statsd.instance).to receive(:increment).with("notifications.skipped.feature_disabled")
      expect {
        described_class.perform_async(notification.id)
        described_class.drain
      }.not_to change { Communication.count }
    end

    it "logs and cancels notification when patient doesn't have a mobile number" do
      notification.patient.phone_numbers.update_all(phone_type: :invalid)
      expect(Statsd.instance).to receive(:increment).with("notifications.skipped.no_mobile_number")
      expect {
        described_class.perform_async(notification.id)
        described_class.drain
      }.not_to change { Communication.count }
      expect(notification.reload.status).to eq("cancelled")
    end

    it "passes a block to the communication channel that updates the notification in a transaction with communication creation" do
      communication = create(:communication)
      allow(Messaging::Twilio::ReminderSms).to receive(:send_message) do |_, &block|
        block.call(communication)
      end

      described_class.perform_async(notification.id)
      described_class.drain
      expect(notification.reload.status).to eq("sent")
      expect(notification.communications.first).to eq(communication)
    end

    it "localizes the message based on facility state, not patient address" do
      mock_successful_delivery
      notification.patient.address.update!(state: "maharashtra")
      notification.subject.facility.update!(state: "punjab")
      localized_message = I18n.t(
        notification.message,
        {
          facility_name: notification.subject.facility.name,
          locale: "pa-Guru-IN"
        }
      )

      expect(Messaging::Twilio::ReminderSms).to receive(:send_message).with(
        recipient_number: notification.patient.latest_mobile_number,
        message: localized_message
      )
      described_class.perform_async(notification.id)
      described_class.drain
    end

    it "does not create a communication or update notification status if the notification status is not 'scheduled'" do
      notification = create(:notification, status: "pending")

      expect(Statsd.instance).to receive(:increment).with("notifications.skipped.not_scheduled")
      expect {
        described_class.perform_async(notification.id)
        described_class.drain
      }.not_to change { Communication.count }
      expect(notification.reload.status).to eq("pending")
    end

    it "cancels the notification if twilio responds with invalid phone number error" do
      allow(Messaging::Twilio::ReminderSms).to receive(:send_message).and_raise(Messaging::Twilio::Error.new("An error", 21211))
      expect {
        described_class.perform_async(notification.id)
        described_class.drain
      }.not_to change { Communication.count }
      expect(notification.reload.status).to eq("cancelled")
    end

    it "raises an error if appointment notification is not found" do
      expect {
        described_class.perform_async("does-not-exist")
        described_class.drain
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "does not send if the notification is cancelled" do
      mock_successful_delivery
      notification.update!(status: "cancelled")
      expect {
        described_class.perform_async(notification.id)
        described_class.drain
      }.not_to change { Communication.count }
    end
  end
end
