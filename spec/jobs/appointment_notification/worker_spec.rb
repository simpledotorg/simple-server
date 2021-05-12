require "rails_helper"

RSpec.describe AppointmentNotification::Worker, type: :job do
  before do
    Flipper.enable(:appointment_reminders)
    allow(Statsd.instance).to receive(:increment).with(anything)
  end

  describe "#perform" do
    let(:reminder) { create(:appointment_reminder, status: "scheduled", message: "sms.appointment_reminders.missed_visit_whatsapp_reminder") }
    let(:communication_type) { "missed_visit_whatsapp_reminder" }
    let(:notification_service) { double }

    def mock_successful_delivery
      allow_any_instance_of(NotificationService).to receive(:send_whatsapp).and_return(notification_service)
      allow(notification_service).to receive(:status).and_return("sent")
      allow(notification_service).to receive(:sid).and_return("12345")
    end

    it "sends a whatsapp message when communication_type is whatsapp" do
      mock_successful_delivery

      expect(Statsd.instance).to receive(:increment).with("appointment_notification.worker.sent.whatsapp")
      expect_any_instance_of(NotificationService).to receive(:send_whatsapp)
      described_class.perform_async(reminder.id, communication_type)
      described_class.drain
    end

    it "sends sms when communication_type is sms" do
      allow_any_instance_of(NotificationService).to receive(:send_sms).and_return(notification_service)
      allow(notification_service).to receive(:status).and_return("sent")
      allow(notification_service).to receive(:sid).and_return("12345")

      expect(Statsd.instance).to receive(:increment).with("appointment_notification.worker.sent.sms")
      expect_any_instance_of(NotificationService).to receive(:send_sms)
      described_class.perform_async(reminder.id, "missed_visit_sms_reminder")
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
        described_class.perform_async(reminder.id, communication_type)
        described_class.drain
      }.to change { Communication.count }.by(1)
    end

    it "does not create a NotificationService or Communication if appointment has previously been successfully communicated" do
      mock_successful_delivery

      previous_communication = create(:communication, :missed_visit_whatsapp_reminder, appointment: reminder.appointment)
      create(:twilio_sms_delivery_detail, :sent, communication: previous_communication)

      expect_any_instance_of(NotificationService).not_to receive(:send_whatsapp)
      expect {
        described_class.perform_async(reminder.id, communication_type)
        described_class.drain
      }.not_to change { Communication.count }
    end

    it "creates a NotificationService and Communication if attempt has previously been made and failed" do
      mock_successful_delivery

      previous_communication = create(:communication, :missed_visit_whatsapp_reminder, appointment: reminder.appointment)
      create(:twilio_sms_delivery_detail, :failed, communication: previous_communication)

      expect_any_instance_of(NotificationService).to receive(:send_whatsapp)
      expect {
        described_class.perform_async(reminder.id, communication_type)
        described_class.drain
      }.to change { Communication.count }.by(1)
    end

    it "updates the appointment reminder status to 'sent'" do
      mock_successful_delivery

      expect {
        described_class.perform_async(reminder.id, communication_type)
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
      described_class.perform_async(reminder.id, communication_type)
      described_class.drain
    end

    it "defaults to English if the patient has no address" do
      mock_successful_delivery

      reminder.patient.update!(address_id: nil)
      localized_message = I18n.t(
        reminder.message,
        {
          facility_name: reminder.appointment.facility.name,
          locale: "en"
        }
      )

      expect_any_instance_of(NotificationService).to receive(:send_whatsapp).with(
        reminder.patient.latest_mobile_number,
        localized_message,
        "https://localhost/api/v3/twilio_sms_delivery"
      )
      described_class.perform_async(reminder.id, communication_type)
      described_class.drain
    end

    it "defaults to English if patient's address is invalid" do
      mock_successful_delivery

      reminder.patient.address.update!(state: "Unknown State")
      localized_message = I18n.t(
        reminder.message,
        {
          facility_name: reminder.appointment.facility.name,
          locale: "en"
        }
      )

      expect_any_instance_of(NotificationService).to receive(:send_whatsapp).with(
        reminder.patient.latest_mobile_number,
        localized_message,
        "https://localhost/api/v3/twilio_sms_delivery"
      )
      described_class.perform_async(reminder.id, communication_type)
      described_class.drain
    end

    it "reports an error and does not create a communication if the appointment notification status is not 'scheduled'" do
      appointment_reminder = create(:appointment_reminder, status: "pending")

      expect(Sentry).to receive(:capture_message)
      expect {
        described_class.perform_async(appointment_reminder.id, communication_type)
        described_class.drain
      }.not_to change { Communication.count }
      expect(appointment_reminder.reload.status).to eq("pending")
    end

    it "reports an error and does not create a communication if an error is received from twilio" do
      expect(Sentry).to receive(:capture_message)
      expect {
        described_class.perform_async(reminder.id, communication_type)
        described_class.drain
      }.not_to change { Communication.count }
      expect(reminder.reload.status).to eq("scheduled")
    end

    it "raises an error if appointment reminder is not found" do
      expect {
        described_class.perform_async("does-not-exist", communication_type)
        described_class.drain
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
