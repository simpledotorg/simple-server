require 'rails_helper'

RSpec.describe AppointmentNotificationService do
  include ActiveJob::TestHelper

  context '#three_days_after_missed_visit' do
    let!(:user) { create(:user) }
    let!(:facility_1) { create(:facility) }
    let!(:facility_2) { create(:facility) }
    let!(:overdue_appointments_from_facility_1) { create_list(:appointment, 10, :overdue, facility: facility_1) }
    let!(:overdue_appointments_from_facility_2) { create_list(:appointment, 10, :overdue, facility: facility_2) }
    let!(:overdue_appointments) { overdue_appointments_from_facility_1 + overdue_appointments_from_facility_2 }
    let!(:recently_overdue_appointments) do
      create_list(:appointment,
                  10,
                  facility: facility_1,
                  scheduled_date: 1.day.ago,
                  status: :scheduled)
    end

    before do
      allow(ENV).to receive(:fetch).and_call_original

      @sms_response_double = double('SmsNotificationServiceResponse')
      allow_any_instance_of(SmsNotificationService).to receive(:send_reminder_sms).and_return(@sms_response_double)
      allow(@sms_response_double).to receive(:sid).and_return(SecureRandom.uuid)
      allow(@sms_response_double).to receive(:status).and_return('queued')
    end

    it 'should spawn sms reminder jobs' do
      reminder_batch_size = 2

      assert_enqueued_jobs 10 do
        AppointmentNotificationService.new(user, reminder_batch_size).send_after_missed_visit
      end
    end

    it 'should send sms reminders to eligible overdue appointments' do
      perform_enqueued_jobs { AppointmentNotificationService.new(user, 2).send_after_missed_visit }

      eligible_appointments = overdue_appointments.select { |a| a.communications.present? }
      expect(eligible_appointments).to_not be_empty
    end

    it 'should ignore appointments which are recently overdue (< 3 days)' do
      perform_enqueued_jobs { AppointmentNotificationService.new(user, 2).send_after_missed_visit }

      ineligible_appointments = recently_overdue_appointments.select { |a| a.communications.present? }
      expect(ineligible_appointments).to be_empty
    end

    it 'should skip sending reminders for appointments for which reminders are already sent' do
      perform_enqueued_jobs { AppointmentNotificationService.new(user, 2).send_after_missed_visit }

      eligible_appointments = overdue_appointments.select { |a| a.communications.present? }
      expect(eligible_appointments).to_not be_empty

      assert_performed_jobs 0 do
        AppointmentNotificationService.new(user, 2).send_after_missed_visit
      end
    end

    it 'should send reminders for appointments for which previous reminders failed' do
      reminder_batch_size = 3

      allow(@sms_response_double).to receive(:status).and_return('failed')
      perform_enqueued_jobs { AppointmentNotificationService.new(user, reminder_batch_size).send_after_missed_visit }

      eligible_appointments = overdue_appointments.select { |a| a.communications.present? }
      expect(eligible_appointments).to_not be_empty

      assert_performed_jobs 8 do
        AppointmentNotificationService.new(user, reminder_batch_size).send_after_missed_visit
      end
    end

    it 'should only send reminders for appointments under whitelisted facilities' do
      allow(ENV).to receive(:fetch).with('TARGETED_RELEASE_FACILITY_IDS').and_return(facility_1.id)

      assert_performed_jobs 5 do
        AppointmentNotificationService.new(user, 2).send_after_missed_visit
      end
    end
  end
end
