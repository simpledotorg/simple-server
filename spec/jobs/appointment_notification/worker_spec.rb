require "rails_helper"

RSpec.describe AppointmentNotification::Worker, type: :job do
  describe "#perform" do
    before do
      Flipper.enable(:notifications)
      Flipper.enable(:experiment)
      allow(Metrics).to receive(:increment).with(anything)
      messaging_channel = Messaging::Twilio::ReminderSms
      allow(CountryConfig.current).to receive(:[]).and_call_original
      allow(CountryConfig.current).to receive(:[]).with(:appointment_reminders_channel).and_return(messaging_channel.to_s)
    end

    def mock_successful_twilio_delivery
      twilio_client = double("TwilioClientDouble")
      response_double = double("TwilioResponse")

      allow(response_double).to receive(:status).and_return("queued")
      allow(response_double).to receive(:sid).and_return("1234")
      allow(Twilio::REST::Client).to receive(:new).and_return(twilio_client)
      allow(twilio_client).to receive_message_chain("messages.create").and_return(response_double)
    end

    it "only sends 'scheduled' notifications" do
      mock_successful_twilio_delivery

      pending_notification = create(:notification, status: "pending")
      cancelled_notification = create(:notification, status: "cancelled")

      expect(Metrics).to receive(:increment)
        .with("notifications_skipped", {reason: "not_scheduled"})
        .exactly(2).times

      described_class.perform_async(pending_notification.id)
      described_class.perform_async(cancelled_notification.id)
      described_class.drain

      expect(pending_notification.reload.status).to eq("pending")
      expect(cancelled_notification.reload.status).to eq("cancelled")
    end

    it "logs but creates nothing when notifications and experiment flags are disabled" do
      Flipper.disable(:notifications)
      Flipper.disable(:experiment)
      notification = create(:notification, status: :scheduled)

      expect(Metrics).to receive(:increment).with("notifications_skipped", {reason: "feature_disabled"})
      expect {
        described_class.perform_async(notification.id)
        described_class.drain
      }.not_to change { Communication.count }
    end

    it "raises an error if appointment notification is not found" do
      expect {
        described_class.perform_async("does-not-exist")
        described_class.drain
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
