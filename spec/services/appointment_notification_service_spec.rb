require "rails_helper"

RSpec.describe AppointmentNotificationService do
  describe "#send_after_missed_visit" do
    let(:overdue_appointment) { create(:appointment, :overdue, remind_on: Date.current) }
    let(:overdue_appointment_relation) do
      Appointment.where(id: overdue_appointment.id).includes(patient: [:phone_numbers], facility: {facility_group: :organization})
    end
    let(:overdue_appointments) do
      overdue_appointment_ids = create_list(:appointment, 2, :overdue, remind_on: Date.current)
      Appointment.where(id: overdue_appointment_ids)
        .includes(patient: [:phone_numbers], facility: {facility_group: :organization})
    end
    let(:recently_overdue_appointments) do
      recently_overdue_appointment_ids = create_list(:appointment, 2, scheduled_date: 1.day.ago, status: :scheduled, remind_on: Date.current)
      Appointment.where(id: recently_overdue_appointment_ids)
        .includes(patient: [:phone_numbers], facility: {facility_group: :organization})
    end

    before do
      allow_any_instance_of(AppointmentNotification::Worker).to receive(:perform)
    end

    it "spawns a reminder job for each appointment with a remind_on of today" do
      expect {
        AppointmentNotificationService.send_after_missed_visit(appointments: overdue_appointments)
      }.to change(AppointmentNotification::Worker.jobs, :size).by(overdue_appointments.count)
    end

    it "ignores appointments which are recently overdue (< 3 days)" do
      expect {
        AppointmentNotificationService.send_after_missed_visit(appointments: recently_overdue_appointments)
      }.to change(AppointmentNotification::Worker.jobs, :size).by(0)
    end

    it "spawns reminder jobs for each appointment with a remind_on before today" do
      ids = create(:appointment, :overdue, remind_on: 100.days.ago)
      appointments = Appointment.where(id: ids)
      expect {
        AppointmentNotificationService.send_after_missed_visit(appointments: appointments)
      }.to change(AppointmentNotification::Worker.jobs, :size).by(1)
    end

    it "creates appointment reminders for provided appointments" do
      expect(overdue_appointment.appointment_reminders).to be_empty
      AppointmentNotificationService.send_after_missed_visit(appointments: overdue_appointment_relation)
      expect(overdue_appointment.appointment_reminders).not_to be_empty
    end

    it "should send reminders for appointments for which previous reminders of the type failed" do
      overdue_appointments.each do |appointment|
        communication = FactoryBot.create(:communication, communication_type: "missed_visit_sms_reminder",
                                                          detailable: create(:twilio_sms_delivery_detail, :failed))
        appointment.communications << communication
      end

      expect {
        AppointmentNotificationService.send_after_missed_visit(appointments: overdue_appointments)
      }.to change(AppointmentNotification::Worker.jobs, :size).by(overdue_appointments.count)
    end

    it "should skip reminders for appointments for which previous reminders have succeeded" do
      overdue_appointments.each do |appointment|
        communication = FactoryBot.create(:communication, communication_type: "missed_visit_sms_reminder",
                                                          detailable: create(:twilio_sms_delivery_detail, :sent))
        appointment.communications << communication
      end

      expect {
        AppointmentNotificationService.send_after_missed_visit(appointments: overdue_appointments)
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

      eligible_appointments = eligible_patients.map { |patient| create(:appointment, :overdue, patient: patient, remind_on: Date.current) }
      ineligible_appointments = ineligible_patients.map { |patient| create(:appointment, :overdue, patient: patient, remind_on: Date.current) }

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
