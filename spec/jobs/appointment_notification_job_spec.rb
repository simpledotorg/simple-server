require 'rails_helper'

RSpec.describe AppointmentNotificationJob, type: :job do
  include ActiveJob::TestHelper

  before do
    sms_response_double = double('SmsNotificationServiceResponse')
    allow_any_instance_of(SmsNotificationService).to receive(:send_reminder_sms).and_return(sms_response_double)
    allow(sms_response_double).to receive(:sid).and_return(SecureRandom.uuid)
    allow(sms_response_double).to receive(:status).and_return('queued')
  end

  it 'sends reminder SMSes for all appointments and creates communication entries for them' do
    assert_performed_jobs 1 do
      described_class.perform_later(create_list(:appointment, 3, :overdue),
                                    'missed_visit_sms_reminder',
                                    create(:user))
    end

    expect(Communication.count).to eq(3)
  end

  pending 'should discard the job if there are any exceptions during the job'
end
