require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe AppointmentNotification::Worker, type: :job do
  before do
    sms_response_double = double('SmsNotificationServiceResponse')
    allow_any_instance_of(SmsNotificationService).to receive(:send_reminder_sms).and_return(sms_response_double)
    allow(sms_response_double).to receive(:sid).and_return(SecureRandom.uuid)
    allow(sms_response_double).to receive(:status).and_return('queued')
  end

  it 'sends reminder SMSes for all appointments and creates communication entries for them' do
    expect {
      described_class.perform_async(create(:user).id,
                                    create_list(:appointment, 3, :overdue).map(&:id),
                                    'missed_visit_sms_reminder')
    }.to change(described_class.jobs, :size).by(1)

    described_class.drain

    expect(Communication.count).to eq(3)
  end

  it 'should skip the appointment if there are any Twilio errors during the job', skip_before: true do
    expect(Raven).to receive(:capture_message).and_return(true)

    sms_response_double = double('SmsNotificationServiceResponse')

    appointment_number = 1
    allow_any_instance_of(SmsNotificationService).to receive(:send_reminder_sms) do
      raise Twilio::REST::TwilioError if appointment_number > 2
      appointment_number += 1
      sms_response_double
    end

    allow(sms_response_double).to receive(:sid).and_return(SecureRandom.uuid)
    allow(sms_response_double).to receive(:status).and_return('queued')

    expect {
      described_class.perform_async(create(:user).id,
                                    create_list(:appointment, 3, :overdue).map(&:id),
                                    'missed_visit_sms_reminder')
    }.to change(described_class.jobs, :size).by(1)

    described_class.drain

    expect(Communication.count).to eq(2)
  end
end
