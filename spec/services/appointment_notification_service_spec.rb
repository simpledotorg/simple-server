require 'rails_helper'

RSpec.describe AppointmentNotificationService do
  context '#send_after_missed_visit' do
    let!(:ihci) { create(:organization, name: 'IHCI') }
    let!(:path) { create(:organization, name: 'PATH') }
    let!(:facility_group_1) { create(:facility_group, organization: ihci) }
    let!(:facility_group_2) { create(:facility_group, organization: path) }
    let!(:facility_1) { create(:facility, facility_group: facility_group_1) }
    let!(:facility_2) { create(:facility, facility_group: facility_group_2) }
    let!(:overdue_appointments_from_facility_1) { create_list(:appointment, 4, :overdue, facility: facility_1) }
    let!(:overdue_appointments_from_facility_2) { create_list(:appointment, 4, :overdue, facility: facility_2) }
    let!(:all_overdue_appointments) { overdue_appointments_from_facility_1 + overdue_appointments_from_facility_2 }
    let!(:recently_overdue_appointments_for_facility_1) do
      create_list(:appointment,
                  2,
                  facility: facility_1,
                  scheduled_date: 1.day.ago,
                  status: :scheduled)
    end

    before do
      @sms_response_double = double('SmsNotificationServiceResponse')
      allow_any_instance_of(SmsNotificationService).to receive(:send_reminder_sms).and_return(@sms_response_double)
      allow(@sms_response_double).to receive(:sid).and_return(SecureRandom.uuid)
      allow(@sms_response_double).to receive(:status).and_return('queued')
    end

    it 'should spawn sms reminder jobs' do
      expect {
        AppointmentNotificationService.new(ihci).send_after_missed_visit(schedule_at: Time.current)
      }.to change(AppointmentNotification::Worker.jobs, :size).by(1)
    end

    it 'should send sms reminders to eligible overdue appointments for the specific organization' do
      AppointmentNotificationService.new(ihci).send_after_missed_visit(schedule_at: Time.current)
      AppointmentNotification::Worker.drain

      eligible_appointments = all_overdue_appointments.select { |a| a.communications.present? }
      expect(eligible_appointments.count).to eq(4)
    end

    it 'should ignore appointments which are recently overdue (< 3 days)' do
      AppointmentNotificationService.new(ihci).send_after_missed_visit(days_overdue: 3, schedule_at: Time.current)
      AppointmentNotification::Worker.drain

      ineligible_appointments = recently_overdue_appointments_for_facility_1.select { |a| a.communications.present? }
      expect(ineligible_appointments).to be_empty
    end

    it 'should skip sending reminders for appointments for which reminders are already sent' do
      AppointmentNotificationService.new(ihci).send_after_missed_visit(schedule_at: Time.current)
      AppointmentNotification::Worker.drain

      appointments_with_reminders_sent = overdue_appointments_from_facility_1.select { |a| a.communications.present? }
      expect(appointments_with_reminders_sent.count).to eq(4)

      reminders_to_be_sent_for_ihci = 0

      expect {
        AppointmentNotificationService.new(ihci).send_after_missed_visit(schedule_at: Time.current)
      }.to change(AppointmentNotification::Worker.jobs, :size).by(reminders_to_be_sent_for_ihci)
    end

    it 'sending reminders for an organization should not affect reminders for another' do
      AppointmentNotificationService.new(ihci).send_after_missed_visit(schedule_at: Time.current)
      AppointmentNotification::Worker.drain

      expect {
        AppointmentNotificationService.new(path).send_after_missed_visit(schedule_at: Time.current)
      }.to change(AppointmentNotification::Worker.jobs, :size).by(1)
    end

    it 'should send reminders for appointments for which previous reminders failed' do
      allow(@sms_response_double).to receive(:status).and_return('failed')

      AppointmentNotificationService.new(ihci).send_after_missed_visit(schedule_at: Time.current)
      AppointmentNotification::Worker.drain

      appointments_with_reminders_failed = all_overdue_appointments.select { |a| a.communications.any?(&:unsuccessful?) }
      expect(appointments_with_reminders_failed.count).to eq(4)

      expect {
        AppointmentNotificationService.new(ihci).send_after_missed_visit(schedule_at: Time.current)
      }.to change(AppointmentNotification::Worker.jobs, :size).by(1)
    end

    it 'should only send reminders to patients who have granted consent' do
      overdue_appointments =
          [create(:patient), create(:patient, :denied)].map do |patient|
            create(:appointment, :overdue, patient: patient, facility: facility_1)
          end

      AppointmentNotificationService.new(ihci).send_after_missed_visit(schedule_at: Time.current)
      AppointmentNotification::Worker.drain

      eligible_appointments = overdue_appointments.select { |a| a.communications.present? }
      expect(eligible_appointments.count).to eq(1)
    end
  end
end
