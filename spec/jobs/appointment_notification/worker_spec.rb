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
        message: "#{Notification::APPOINTMENT_REMINDER_MSG_PREFIX}.whatsapp")
    }

    def mock_successful_delivery
      response_double = double
      allow(response_double).to receive(:status).and_return("sent")
      allow(response_double).to receive(:sid).and_return("12345")
      allow(Messaging::Twilio::Whatsapp).to receive(:send_message).and_return(response_double)
      allow(Messaging::Twilio::ReminderSms).to receive(:send_message).and_return(response_double)
    end

    it "logs but creates nothing when notifications and experiment flags are disabled" do
      Flipper.disable(:notifications)
      Flipper.disable(:experiment)

      expect(Statsd.instance).to receive(:increment).with("appointment_notification.worker.skipped.feature_disabled")
      expect {
        described_class.perform_async(notification.id)
        described_class.drain
      }.not_to change { Communication.count }
    end

    it "logs and cancels notification when patient doesn't have a mobile number" do
      notification.patient.phone_numbers.update_all(phone_type: :invalid)
      expect(Statsd.instance).to receive(:increment).with("appointment_notification.worker.skipped.no_mobile_number")
      expect {
        described_class.perform_async(notification.id)
        described_class.drain
      }.not_to change { Communication.count }
      expect(notification.reload.status).to eq("cancelled")
    end

    it "creates communications when notifications is enabled" do
      mock_successful_delivery

      expect {
        described_class.perform_async(notification.id)
        described_class.drain
      }.to change { Communication.count }.by(1)
    end

    it "creates communications when experiment is enabled" do
      Flipper.disable(:notifications)
      Flipper.enable(:experiment)

      mock_successful_delivery

      expect {
        described_class.perform_async(notification.id)
        described_class.drain
      }.to change { Communication.count }.by(1)
    end

    it "creates a Communication with twilio response status and sid" do
      mock_successful_delivery

      expect(Communication).to receive(:create_with_twilio_details!).with(
        notification: notification,
        twilio_sid: "12345",
        twilio_msg_status: "sent",
        communication_type: "sms"
      ).and_call_original
      expect {
        described_class.perform_async(notification.id)
        described_class.drain
      }.to change { Communication.count }.by(1)
    end

    it "does not attempt to resend the same communication type even if previous attempt failed" do
      mock_successful_delivery

      previous_whatsapp = create(:communication, :whatsapp, notification: notification)
      create(:twilio_sms_delivery_detail, :failed, communication: previous_whatsapp)

      expect(Messaging::Twilio::ReminderSms).to receive(:send_message)
      described_class.perform_async(notification.id)
      described_class.drain
    end

    it "updates the appointment notification status to 'sent'" do
      mock_successful_delivery

      expect {
        described_class.perform_async(notification.id)
        described_class.drain
      }.to change { notification.reload.status }.from("scheduled").to("sent")
    end

    it "localizes the message based on facility state, not patient address" do
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

      expect(Statsd.instance).to receive(:increment).with("appointment_notification.worker.skipped.not_scheduled")
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
