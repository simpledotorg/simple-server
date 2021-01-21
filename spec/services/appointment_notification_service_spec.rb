require "rails_helper"

RSpec.describe AppointmentNotificationService do
  context "#send_after_missed_visit" do
    let!(:overdue_appointments) do
      overdue_appointment_ids = create_list(:appointment, 4, :overdue).map(&:id)
      Appointment.where(id: overdue_appointment_ids)
        .includes(patient: [:phone_numbers], facility: {facility_group: :organization})
    end

    let!(:recently_overdue_appointments) do
      recently_overdue_appointment_ids = create_list(:appointment, 2, scheduled_date: 1.day.ago, status: :scheduled).map(&:id)
      Appointment.where(id: recently_overdue_appointment_ids)
        .includes(patient: [:phone_numbers], facility: {facility_group: :organization})
    end

    before do
      allow_any_instance_of(AppointmentNotification::Worker).to receive(:perform)
    end

    it "spawns a reminder job for each appointment" do
      expect {
        AppointmentNotificationService.send_after_missed_visit(appointments: overdue_appointments)
      }.to change(AppointmentNotification::Worker.jobs, :size).by(4)
    end

    it "ignores appointments which are recently overdue (< 3 days)" do
      expect {
        AppointmentNotificationService.send_after_missed_visit(appointments: recently_overdue_appointments)
      }.to change(AppointmentNotification::Worker.jobs, :size).by(0)
    end

    it "schedules a whatsapp reminder for the correct time when whatsapp is enabled" do
      whatsapp_appointment_reminders = ENV["ENABLE_WHATSAPP_APPOINTMENT_REMINDERS"]
      ENV["ENABLE_WHATSAPP_APPOINTMENT_REMINDERS"] = "true"

      message_time = DateTime.now
      allow(Communication).to receive(:next_messaging_time).and_return(message_time)
      appointment = overdue_appointments.first

      appointments = Appointment.where(id: appointment.id)

      expect(AppointmentNotification::Worker).to receive(:perform_at).with(
        message_time,
        appointment.id,
        "missed_visit_whatsapp_reminder"
      )

      AppointmentNotificationService.send_after_missed_visit(appointments: appointments)

      ENV["ENABLE_WHATSAPP_APPOINTMENT_REMINDERS"] = whatsapp_appointment_reminders
    end

    it "schedules an SMS reminder for the correct time when whatsapp is enabled" do
      whatsapp_appointment_reminders = ENV["ENABLE_WHATSAPP_APPOINTMENT_REMINDERS"]
      ENV["ENABLE_WHATSAPP_APPOINTMENT_REMINDERS"] = "false"

      message_time = DateTime.now
      allow(Communication).to receive(:next_messaging_time).and_return(message_time)
      appointment = overdue_appointments.first

      appointments = Appointment.where(id: appointment.id)

      expect(AppointmentNotification::Worker).to receive(:perform_at).with(
        message_time,
        appointment.id,
        "missed_visit_sms_reminder"
      )

      AppointmentNotificationService.send_after_missed_visit(appointments: appointments)

      ENV["ENABLE_WHATSAPP_APPOINTMENT_REMINDERS"] = whatsapp_appointment_reminders
    end

    context "if WHATSAPP_APPOINTMENT_REMINDERS feature is disabled" do
      it "should skip sending reminders for appointments for which SMS reminders are already sent" do
        expect(FeatureToggle).to receive(:enabled?).with("WHATSAPP_APPOINTMENT_REMINDERS").and_return(false)

        overdue_appointments.each do |appointment|
          communication = FactoryBot.create(:communication, communication_type: "missed_visit_sms_reminder",
                                                            detailable: create(:twilio_sms_delivery_detail, :sent))
          appointment.communications << communication
        end

        expect {
          AppointmentNotificationService.send_after_missed_visit(appointments: overdue_appointments)
        }.to change(AppointmentNotification::Worker.jobs, :size).by(0)
      end
    end

    context "if WHATSAPP_APPOINTMENT_REMINDERS feature is enabled" do
      it "should skip sending reminders for appointments for which WhatsApp reminders are already sent" do
        expect(FeatureToggle).to receive(:enabled?).with("WHATSAPP_APPOINTMENT_REMINDERS").and_return(true)

        overdue_appointments.each do |appointment|
          communication = FactoryBot.create(:communication, communication_type: "missed_visit_whatsapp_reminder",
                                                            detailable: create(:twilio_sms_delivery_detail, :sent))
          appointment.communications << communication
        end

        expect {
          AppointmentNotificationService.send_after_missed_visit(appointments: overdue_appointments)
        }.to change(AppointmentNotification::Worker.jobs, :size).by(0)
      end
    end

    it "should send reminders for appointments for which previous reminders failed" do
      overdue_appointments.each do |appointment|
        communication = FactoryBot.create(:communication, communication_type: "missed_visit_whatsapp_reminder",
                                                          detailable: create(:twilio_sms_delivery_detail, :failed))
        appointment.communications << communication
      end

      expect {
        AppointmentNotificationService.send_after_missed_visit(appointments: overdue_appointments)
      }.to change(AppointmentNotification::Worker.jobs, :size).by(4)
    end

    it "should only send reminders to patients who are eligible" do
      mobile_number = create(:patient_phone_number, phone_type: :mobile)
      landline_number = create(:patient_phone_number, phone_type: :landline)
      invalid_number = create(:patient_phone_number, phone_type: :invalid)

      patients = [create(:patient),
        create(:patient, :denied),
        create(:patient, status: "dead"),
        create(:patient, phone_numbers: [mobile_number, landline_number, invalid_number])]

      appointments = patients.map { |patient| create(:appointment, :overdue, patient: patient) }
      overdue_appointments = Appointment.where(id: appointments)
        .includes(patient: [:phone_numbers])
        .includes(facility: {facility_group: :organization})
      eligible_appointments = overdue_appointments.eligible_for_reminders(days_overdue: 3)

      expect {
        AppointmentNotificationService.send_after_missed_visit(appointments: overdue_appointments)
      }.to change(AppointmentNotification::Worker.jobs, :size).by(eligible_appointments.size)
    end
  end
end
