require "rails_helper"

RSpec.describe AppointmentNotificationService do
  describe "#send_after_missed_visit" do
    let(:overdue_appointment) { create(:appointment, scheduled_date: 3.days.ago, remind_on: Date.current) }
    let(:overdue_appointment_relation) do
      Appointment.where(id: overdue_appointment.id).includes(patient: [:phone_numbers], facility: {facility_group: :organization})
    end

    before do
      allow_any_instance_of(AppointmentNotification::Worker).to receive(:perform)
    end

    it "spawns a reminder job for each appointment with a remind_on of today" do
      overdue_appointment_ids = create_list(:appointment, 2, scheduled_date: 3.days.ago, remind_on: Date.current)
      overdue_appointments = Appointment.where(id: overdue_appointment_ids)
        .includes(patient: [:phone_numbers], facility: {facility_group: :organization})
      expect {
        AppointmentNotificationService.send_after_missed_visit(appointments: overdue_appointments)
      }.to change(AppointmentNotification::Worker.jobs, :size).by(overdue_appointments.count)
    end

    it "ignores appointments that are overdue by fewer than 3 days" do
      recently_overdue_appointment_ids = create_list(:appointment, 2, scheduled_date: 2.days.ago, status: :scheduled, remind_on: 2.days.ago)
      recently_overdue_appointments = Appointment.where(id: recently_overdue_appointment_ids)
        .includes(patient: [:phone_numbers], facility: {facility_group: :organization})
      expect {
        AppointmentNotificationService.send_after_missed_visit(appointments: recently_overdue_appointments)
      }.to change(AppointmentNotification::Worker.jobs, :size).by(0)
    end

    it "ignores appointments that are overdue by more than 3 days" do
      too_overdue_ids = create_list(:appointment, 2, scheduled_date: 4.days.ago, remind_on: Date.current)
      too_overdue = Appointment.where(id: too_overdue_ids)
        .includes(patient: [:phone_numbers], facility: {facility_group: :organization})
      expect {
        AppointmentNotificationService.send_after_missed_visit(appointments: too_overdue)
      }.to change(AppointmentNotification::Worker.jobs, :size).by(0)
    end

    it "creates appointment reminders for provided appointments" do
      expect {
        AppointmentNotificationService.send_after_missed_visit(appointments: overdue_appointment_relation)
      }.to change { overdue_appointment.appointment_reminders.count }.by(1)
    end

    it "should skip reminders for appointments that already have an appointment reminder" do
      create(:appointment_reminder, appointment: overdue_appointment)
      expect {
        AppointmentNotificationService.send_after_missed_visit(appointments: overdue_appointment_relation)
      }.not_to change(AppointmentNotification::Worker.jobs, :size)
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
        expect(appointment.appointment_reminders.count).to eq(1)
      end
      ineligible_appointments.each do |appointment|
        expect(appointment.appointment_reminders.count).to eq(0)
      end
    end
  end
end
