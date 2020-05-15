require 'rails_helper'

RSpec.describe AppointmentNotificationService do
  context '#send_after_missed_visit' do
    let!(:overdue_appointments) do
      overdue_appointment_ids = create_list(:appointment, 4, :overdue).map(&:id)
      Appointment.where(id: overdue_appointment_ids)
                 .includes(patient: [:phone_numbers], facility: { facility_group: :organization })
    end

    let!(:recently_overdue_appointments) do
      recently_overdue_appointment_ids = create_list(:appointment, 2, scheduled_date: 1.day.ago, status: :scheduled).map(&:id)
      Appointment.where(id: recently_overdue_appointment_ids)
                 .includes(patient: [:phone_numbers], facility: { facility_group: :organization })
    end

    before do
      allow_any_instance_of(AppointmentNotification::Worker).to receive(:perform)
    end

    it 'should spawn a sms reminder job for each appointment' do
      expect do
        AppointmentNotificationService.send_after_missed_visit(appointments: overdue_appointments, schedule_at: Time.current)
      end.to change(AppointmentNotification::Worker.jobs, :size).by(4)
    end

    it 'should ignore appointments which are recently overdue (< 3 days)' do
      AppointmentNotificationService.send_after_missed_visit(appointments: recently_overdue_appointments, days_overdue: 3, schedule_at: Time.current)
      AppointmentNotification::Worker.drain

      ineligible_appointments = recently_overdue_appointments.select { |a| a.communications.present? }
      expect(ineligible_appointments).to be_empty
    end

    it 'should skip sending reminders for appointments for which reminders are already sent' do
      #AppointmentNotificationService.send_after_missed_visit(appointments: overdue_appointments, schedule_at: Time.current)
      #AppointmentNotification::Worker.drain

      overdue_appointments.each do |appointment|
        communication = FactoryBot.create(:communication, communication_type: "missed_visit_whatsapp_reminder",
                                          detailable: create(:twilio_sms_delivery_detail, :sent))
        appointment.communications << communication
      end

      expect do
        AppointmentNotificationService.send_after_missed_visit(appointments: overdue_appointments, schedule_at: Time.current)
      end.to change(AppointmentNotification::Worker.jobs, :size).by(0)
    end

    it 'should send reminders for appointments for which previous reminders failed' do
      overdue_appointments.each do |appointment|
        communication = FactoryBot.create(:communication, communication_type: "missed_visit_whatsapp_reminder",
                                          detailable: create(:twilio_sms_delivery_detail, :failed))
        appointment.communications << communication
      end

      expect do
        AppointmentNotificationService.send_after_missed_visit(appointments: overdue_appointments, schedule_at: Time.current)
      end.to change(AppointmentNotification::Worker.jobs, :size).by(4)
    end

    it 'should only send reminders to patients who have granted consent' do
      overdue_appointment_ids =
        [create(:patient), create(:patient, :denied)].map do |patient|
          create(:appointment, :overdue, patient: patient).id
        end

      overdue_appointments = Appointment.where(id: overdue_appointment_ids)

      expect do
        AppointmentNotificationService.send_after_missed_visit(appointments: overdue_appointments, schedule_at: Time.current)
      end.to change(AppointmentNotification::Worker.jobs, :size).by(1)
    end

    context 'when a patient has just landline or invalid numbers' do
      let!(:landline_number) { create(:patient_phone_number, phone_type: :landline) }
      let!(:invalid_number)  { create(:patient_phone_number, phone_type: :invalid) }
      let!(:patient) { create(:patient, phone_numbers: [landline_number, invalid_number]) }

      let!(:overdue_appointments) do
        overdue_appointment_id = create(:appointment, :overdue, patient: patient)[:id]
        Appointment.where(id: overdue_appointment_id)
                   .includes(patient: [:phone_numbers], facility: { facility_group: :organization })
      end

      it 'should skip sending reminders' do
        AppointmentNotificationService.send_after_missed_visit(appointments: overdue_appointments, schedule_at: Time.current)
        AppointmentNotification::Worker.drain

        eligible_appointments = overdue_appointments.select { |a| a.communications.present? }
        expect(eligible_appointments.count).to eq(0)
      end
    end
  end
end
