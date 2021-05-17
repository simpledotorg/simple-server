require "rails_helper"

RSpec.describe AppointmentNotification::Worker, type: :job do
  describe "#perform" do
    before do
      Flipper.enable(:appointment_reminders)
      allow(Statsd.instance).to receive(:increment).with(anything)
    end

    let(:reminder) { create(:appointment_reminder, status: "scheduled", message: "sms.appointment_reminders.missed_visit_whatsapp_reminder") }
    let(:communication_type) { "missed_visit_whatsapp_reminder" }

    def mock_successful_delivery
      response_double = double
      allow_any_instance_of(NotificationService).to receive(:response).and_return(response_double)
      allow(response_double).to receive(:status).and_return("sent")
      allow(response_double).to receive(:sid).and_return("12345")
      twilio_client = double
      allow_any_instance_of(NotificationService).to receive(:client).and_return(twilio_client)
      allow(twilio_client).to receive_message_chain("messages.create")
    end

    it "logs when appointment_reminders flag is disabled" do
      Flipper.disable(:appointment_reminders)

      expect(Statsd.instance).to receive(:increment).with("appointment_notification.worker.skipped.feature_disabled")
      expect {
        described_class.perform_async(reminder.id)
        described_class.drain
      }.not_to change { Communication.count }
    end

    it "sends a whatsapp message when reminder's next_communication_type is whatsapp" do
      mock_successful_delivery

      expect(Statsd.instance).to receive(:increment).with("appointment_notification.worker.sent.whatsapp")
      expect_any_instance_of(NotificationService).to receive(:send_whatsapp)
      described_class.perform_async(reminder.id)
      described_class.drain
    end

    it "sends sms when reminder's next_communication_type is sms" do
      create(:communication, appointment_reminder: reminder, communication_type: "missed_visit_whatsapp_reminder")

      mock_successful_delivery

      expect(Statsd.instance).to receive(:increment).with("appointment_notification.worker.sent.sms")
      expect_any_instance_of(NotificationService).to receive(:send_sms)
      described_class.perform_async(reminder.id)
      described_class.drain
    end

    it "creates a Communication with twilio response status and sid" do
      mock_successful_delivery

      expect(Communication).to receive(:create_with_twilio_details!).with(
        appointment: reminder.appointment,
        appointment_reminder: reminder,
        twilio_sid: "12345",
        twilio_msg_status: "sent",
        communication_type: communication_type
      ).and_call_original
      expect {
        described_class.perform_async(reminder.id)
        described_class.drain
      }.to change { Communication.count }.by(1)
    end

    it "does not create a NotificationService or Communication if reminder has been previously attempted by all available methods" do
      create(:communication, :missed_visit_whatsapp_reminder, appointment: reminder.appointment, appointment_reminder: reminder)
      create(:communication, :missed_visit_sms_reminder, appointment: reminder.appointment, appointment_reminder: reminder)

      expect(Statsd.instance).to receive(:increment).with("appointment_notification.worker.skipped.previously_communicated")
      expect_any_instance_of(NotificationService).not_to receive(:send_whatsapp)
      expect {
        described_class.perform_async(reminder.id)
        described_class.drain
      }.not_to change { Communication.count }
    end

    it "does not attempt to resend the same communication type even if previous attempt failed" do
      mock_successful_delivery

      previous_whatsapp = create(:communication, :missed_visit_whatsapp_reminder, appointment: reminder.appointment, appointment_reminder: reminder)
      create(:twilio_sms_delivery_detail, :failed, communication: previous_whatsapp)

      expect_any_instance_of(NotificationService).to receive(:send_sms)
      described_class.perform_async(reminder.id)
      described_class.drain
    end

    it "updates the appointment reminder status to 'sent'" do
      mock_successful_delivery

      expect {
        described_class.perform_async(reminder.id)
        described_class.drain
      }.to change { reminder.reload.status }.from("scheduled").to("sent")
    end

    it "selects the message language based on patient address" do
      mock_successful_delivery
      reminder.patient.address.update(state: "punjab")
      localized_message = I18n.t(
        reminder.message,
        {
          facility_name: reminder.appointment.facility.name,
          locale: "pa-Guru-IN"
        }
      )

      expect_any_instance_of(NotificationService).to receive(:send_whatsapp).with(
        reminder.patient.latest_mobile_number,
        localized_message,
        "https://localhost/api/v3/twilio_sms_delivery"
      )
      described_class.perform_async(reminder.id)
      described_class.drain
    end

    it "does not create a communication or update reminder status if the appointment reminder status is not 'scheduled'" do
      appointment_reminder = create(:appointment_reminder, status: "pending")

      expect(Statsd.instance).to receive(:increment).with("appointment_notification.worker.skipped.not_scheduled")
      expect {
        described_class.perform_async(appointment_reminder.id)
        described_class.drain
      }.not_to change { Communication.count }
      expect(appointment_reminder.reload.status).to eq("pending")
    end

    it "does not create a communication or update reminder status if an error is received from twilio" do
      expect {
        described_class.perform_async(reminder.id)
        described_class.drain
      }.not_to change { Communication.count }
      expect(reminder.reload.status).to eq("scheduled")
    end

    it "raises an error if appointment reminder is not found" do
      expect {
        described_class.perform_async("does-not-exist")
        described_class.drain
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
