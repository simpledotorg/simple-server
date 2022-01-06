# frozen_string_literal: true

require "rails_helper"

RSpec.describe AppointmentNotificationService do
  describe "#send_after_missed_visit" do
    let(:overdue_appointment) { create(:appointment, scheduled_date: 3.days.ago, remind_on: Date.current) }

    before do
      allow_any_instance_of(AppointmentNotification::Worker).to receive(:perform)
    end

    it "spawns a reminder job for each appointment that is overdue by at least 3 days" do
      create(:appointment, scheduled_date: 3.days.ago, remind_on: Date.current)
      create(:appointment, scheduled_date: 4.days.ago, remind_on: Date.current)

      expect {
        AppointmentNotificationService.send_after_missed_visit(appointments: common_org.appointments)
      }.to change(AppointmentNotification::Worker.jobs, :size).by(2)
    end

    it "spawns a reminder job for appointments with nil remind_on" do
      create(:appointment, scheduled_date: 3.days.ago, remind_on: nil)

      expect {
        AppointmentNotificationService.send_after_missed_visit(appointments: common_org.appointments)
      }.to change(AppointmentNotification::Worker.jobs, :size).by(1)
    end

    it "does not schedule for appointments that are overdue by fewer than 3 days, have a remind_on in the future, have an appointment reminder, or have a communication" do
      _recently_overdue_appointment_ids = create(:appointment, scheduled_date: 2.days.ago, status: :scheduled, remind_on: 2.days.ago)
      appointment_with_reminder = create(:appointment, scheduled_date: 3.days.ago, remind_on: Date.current)
      create(:notification, subject: appointment_with_reminder)
      appointment_with_communication = create(:appointment, scheduled_date: 3.days.ago, remind_on: Date.current)
      create(:notification, subject: appointment_with_communication)
      create(:appointment, scheduled_date: 3.days.ago, remind_on: 1.day.from_now)

      expect {
        AppointmentNotificationService.send_after_missed_visit(appointments: common_org.appointments)
      }.to change(AppointmentNotification::Worker.jobs, :size).by(0)
    end

    it "creates notifications for provided appointments with correct attributes" do
      overdue_appointment
      expect {
        AppointmentNotificationService.send_after_missed_visit(appointments: common_org.appointments)
      }.to change { overdue_appointment.notifications.count }.by(1)
      notification = overdue_appointment.notifications.last
      expect(notification.status).to eq("scheduled")
      expect(notification.remind_on).to eq(Communication.next_messaging_time.to_date)
      expect(notification.purpose).to eq("missed_visit_reminder")
      expect(notification.message).to eq("communications.appointment_reminders.sms")
      expect(notification.status).to eq("scheduled")
    end

    it "should only send reminders to patients who are eligible" do
      mobile_number = create(:patient_phone_number, phone_type: :mobile)
      landline_number = create(:patient_phone_number, phone_type: :landline)
      invalid_number = create(:patient_phone_number, phone_type: :invalid)

      eligible_patients = [
        create(:patient),
        create(:patient, phone_numbers: [mobile_number])
      ]
      ineligible_patients = [
        create(:patient, :denied),
        create(:patient, status: "dead"),
        create(:patient, phone_numbers: [landline_number]),
        create(:patient, phone_numbers: [invalid_number])
      ]

      eligible_appointments = eligible_patients.map do |patient|
        create(:appointment, scheduled_date: 3.days.ago, patient: patient, remind_on: Date.current)
      end
      ineligible_appointments = ineligible_patients.map do |patient|
        create(:appointment, scheduled_date: 3.days.ago, patient: patient, remind_on: Date.current)
      end

      expect {
        AppointmentNotificationService.send_after_missed_visit(appointments: Appointment.where(id: eligible_appointments))
      }.to change(AppointmentNotification::Worker.jobs, :size).by(2)
      eligible_appointments.each do |appointment|
        expect(appointment.notifications.count).to eq(1)
      end
      ineligible_appointments.each do |appointment|
        expect(appointment.notifications.count).to eq(0)
      end
    end
  end
end
