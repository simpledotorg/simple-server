require "rails_helper"

RSpec.describe AppointmentReminders::SendReminderJob, type: :job do
  describe "#perform" do
    let(:reminder) { create(:appointment_reminder, status: "scheduled") }
    let(:notification_service) { double }

    def simulate_successful_delivery
      allow_any_instance_of(NotificationService).to receive(:send_whatsapp).and_return(notification_service)
      allow(notification_service).to receive(:status).and_return("sent")
      allow(notification_service).to receive(:sid).and_return("12345")
    end

    it "sends a whatsapp message when next_communication_type is whatsapp" do
      simulate_successful_delivery

      allow_any_instance_of(AppointmentReminder).to receive(:next_communication_type).and_return("missed_visit_whatsapp_reminder")
      expect_any_instance_of(NotificationService).to receive(:send_whatsapp)
      described_class.perform_async(reminder.id)
      described_class.drain
    end

    it "sends sms when next_communication_type is sms" do
      allow_any_instance_of(NotificationService).to receive(:send_sms).and_return(notification_service)
      allow(notification_service).to receive(:status).and_return("sent")
      allow(notification_service).to receive(:sid).and_return("12345")

      allow_any_instance_of(AppointmentReminder).to receive(:next_communication_type).and_return("missed_visit_sms_reminder")
      expect_any_instance_of(NotificationService).to receive(:send_sms)
      described_class.perform_async(reminder.id)
      described_class.drain
    end

    it "creates a communication with twilio response status and sid" do
      simulate_successful_delivery

      expect(Communication).to receive(:create_with_twilio_details!).with(
        appointment: reminder.appointment,
        appointment_reminder: reminder,
        twilio_sid: "12345",
        twilio_msg_status: "sent",
        communication_type: "missed_visit_whatsapp_reminder"
      ).and_call_original
      expect {
        described_class.perform_async(reminder.id)
        described_class.drain
      }.not_to raise_error
    end

    it "updates the appointment reminder status to 'sent'" do
      simulate_successful_delivery

      expect {
        described_class.perform_async(reminder.id)
        described_class.drain
      }.to change { reminder.reload.status }.from("scheduled").to("sent")
    end

    it "selects the message language based on patient address" do
      simulate_successful_delivery
      reminder.patient.address.update(state: "punjab")
      localized_message = I18n.t(
        reminder.message,
        {
          appointment_date: reminder.appointment.scheduled_date,
          assigned_facility_name: reminder.appointment.facility.name,
          patient_name: reminder.patient.full_name,
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

    it "it defaults to the primary language of the country the server is in if the patient has no address" do
      simulate_successful_delivery

      reminder.patient.update!(address_id: nil)
      localized_message = I18n.t(
        reminder.message,
        {
          appointment_date: reminder.appointment.scheduled_date,
          assigned_facility_name: reminder.appointment.facility.name,
          patient_name: reminder.patient.full_name,
          locale: "hi-IN"
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

    it "reports an error and does not create a communication if the appointment notification status is not 'scheduled'" do
      appointment_reminder = create(:appointment_reminder, status: "pending")
      expect(Sentry).to receive(:capture_message)
      expect {
        described_class.perform_async(appointment_reminder.id)
        described_class.drain
      }.not_to change { Communication.count }
      expect(appointment_reminder.reload.status).to eq("pending")
    end

    it "reports an error and does not create a communication if an error is received from twilio" do
      expect(Sentry).to receive(:capture_message)
      expect {
        described_class.perform_async(reminder.id)
        described_class.drain
      }.not_to change { Communication.count }
      expect(reminder.reload.status).to eq("scheduled")
    end
  end
end
