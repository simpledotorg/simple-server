require 'rails_helper'

RSpec.describe SMSReminderService do
  include ActiveJob::TestHelper

  context '#three_days_after_missed_visit' do
    let!(:user) { create(:user) }
    let!(:facility) { create(:facility) }
    let!(:overdue_appointments) { create_list(:appointment, 10, :overdue, facility: facility) }
    let!(:recently_overdue_appointments) do
      create_list(:appointment,
                  10,
                  facility: facility,
                  scheduled_date: 2.days.ago,
                  status: :scheduled)
    end

    before do
      sms_response_double = double('SmsNotificationServiceResponse')
      allow_any_instance_of(SmsNotificationService).to receive(:send_reminder_sms).and_return(sms_response_double)
      allow(sms_response_double).to receive(:sid).and_return(SecureRandom.uuid)
      allow(sms_response_double).to receive(:status).and_return('queued')

      # expect(ENV).to receive(:fetch).at_least(:once).with("TARGETED_RELEASE_FACILITY_IDS").and_return(facility.id)
    end

    it 'should spawn sms reminder jobs' do
      reminder_batch_size = 2
      number_of_jobs = overdue_appointments.count / reminder_batch_size

      assert_enqueued_jobs number_of_jobs do
        SMSReminderService.new(user, reminder_batch_size).three_days_after_missed_visit
      end
    end

    it 'should send sms reminders to eligible overdue appointments' do
      perform_enqueued_jobs { SMSReminderService.new(user, 2).three_days_after_missed_visit }

      eligible_appointments = overdue_appointments.select { |a| a.communications.present? }
      expect(eligible_appointments).to_not be_empty
    end

    it 'should ignore appointments which are recently overdue (< 3 days)' do
      perform_enqueued_jobs { SMSReminderService.new(user, 2).three_days_after_missed_visit }

      ineligible_appointments = recently_overdue_appointments.select { |a| a.communications.present? }
      expect(ineligible_appointments).to be_empty
    end

    pending 'should only send reminders for appointments under whitelisted facilities'
    pending 'should skip sending reminders to appointments for which reminders are already sent'
  end
end
