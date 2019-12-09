require 'rails_helper'

RSpec.describe AppointmentNotificationService do
  context '#send_after_missed_visit' do
    let!(:facility_1) { create(:facility) }
    let!(:facility_2) { create(:facility) }
    let!(:overdue_appointments_from_facility_1) { create_list(:appointment, 4, :overdue, facility: facility_1) }
    let!(:overdue_appointments_from_facility_2) { create_list(:appointment, 4, :overdue, facility: facility_2) }
    let!(:overdue_appointments) { overdue_appointments_from_facility_1 + overdue_appointments_from_facility_2 }
    let!(:recently_overdue_appointments) do
      create_list(:appointment,
                  2,
                  facility: facility_1,
                  scheduled_date: 1.day.ago,
                  status: :scheduled)
    end
    let!(:patient_1) { create(:patient, reminder_consent: "granted") }
    let!(:patient_2) { create(:patient, reminder_consent: "denied") }
    let!(:patients) { [patient_1, patient_2] }

    before do
      allow(ENV).to receive(:[]).and_call_original

      @sms_response_double = double('SmsNotificationServiceResponse')
      allow_any_instance_of(SmsNotificationService).to receive(:send_reminder_sms).and_return(@sms_response_double)
      allow(@sms_response_double).to receive(:sid).and_return(SecureRandom.uuid)
      allow(@sms_response_double).to receive(:status).and_return('queued')
    end

    it 'should spawn sms reminder jobs' do
      expect {
        AppointmentNotificationService.new.send_after_missed_visit(schedule_at: Time.current)
      }.to change(AppointmentNotification::Worker.jobs, :size).by(1)
    end

    it 'should send sms reminders to eligible overdue appointments' do
      AppointmentNotificationService.new.send_after_missed_visit(schedule_at: Time.current)
      AppointmentNotification::Worker.drain

      eligible_appointments = overdue_appointments.select { |a| a.communications.present? }
      expect(eligible_appointments.count).to eq(8)
    end

    it 'should ignore appointments which are recently overdue (< 3 days)' do
      AppointmentNotificationService.new.send_after_missed_visit(schedule_at: Time.current)
      AppointmentNotification::Worker.drain

      ineligible_appointments = recently_overdue_appointments.select { |a| a.communications.present? }
      expect(ineligible_appointments).to be_empty
    end

    it 'should skip sending reminders for appointments for which reminders are already sent' do
      AppointmentNotificationService.new.send_after_missed_visit(schedule_at: Time.current)
      AppointmentNotification::Worker.drain

      eligible_appointments = overdue_appointments.select { |a| a.communications.present? }
      expect(eligible_appointments).to_not be_empty

      expect {
        AppointmentNotificationService.new.send_after_missed_visit(schedule_at: Time.current)
      }.to change(AppointmentNotification::Worker.jobs, :size).by(0)
    end

    it 'should send reminders for appointments for which previous reminders failed' do
      allow(@sms_response_double).to receive(:status).and_return('failed')

      AppointmentNotificationService.new.send_after_missed_visit(schedule_at: Time.current)
      AppointmentNotification::Worker.drain

      eligible_appointments = overdue_appointments.select { |a| a.communications.present? }
      expect(eligible_appointments).to_not be_empty

      expect {
        AppointmentNotificationService.new.send_after_missed_visit(schedule_at: Time.current)
      }.to change(AppointmentNotification::Worker.jobs, :size).by(1)
    end

    it 'should only send reminders for appointments under whitelisted facilities' do
      allow(ENV).to receive(:[]).with('APPOINTMENT_NOTIFICATION_FACILITY_IDS').and_return(facility_1.id)

      AppointmentNotificationService.new.send_after_missed_visit(schedule_at: Time.current)
      AppointmentNotification::Worker.drain

      eligible_appointments = overdue_appointments.select { |a| a.communications.present? }
      expect(eligible_appointments.count).to eq(4)
    end

    it 'should only send reminder of half the appointments if the rollout percentage is 50%' do
      allow(ENV).to receive(:[]).with('APPOINTMENT_NOTIFICATION_FACILITY_IDS').and_return(facility_1.id)
      allow(ENV).to receive(:[]).with('APPOINTMENT_NOTIFICATION_ROLLOUT_PERCENTAGE').and_return('50')

      AppointmentNotificationService.new.send_after_missed_visit(schedule_at: Time.current)
      AppointmentNotification::Worker.drain

      eligible_appointments = overdue_appointments.select { |a| a.communications.present? }
      expect(eligible_appointments.count).to eq(2)
    end

    it 'should only send reminders to patients who have granted consent' do
      overdue_appointments = patients.map do |patient|
        create(:appointment, :overdue, patient: patient)
      end

      AppointmentNotificationService.new.send_after_missed_visit(schedule_at: Time.current)
      AppointmentNotification::Worker.drain

      eligible_appointments = overdue_appointments.select { |a| a.communications.present? }
      expect(eligible_appointments.count).to eq(1)
    end
  end
end
