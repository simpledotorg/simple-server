require "rails_helper"
include ActiveJob::TestHelper

RSpec.describe AnonymizedDataDownloadMailer, type: :mailer do
  let (:sender_email) { 'help@simple.org' }
  let (:recipient_name) { 'Example User' }
  let (:recipient_email) { 'user@example.com' }
  let (:attachment_file_names) { %w[patients.csv blood_pressures.csv medicines.csv appointments.csv sms_reminders.csv phone_calls.csv] }
  let (:empty_attachment_data) { Hash.new }
  let (:attachment_data) {
    {
      'patients.csv' => [['Id', 'Created At', 'Registration Date', 'Facility Name', 'User', 'Age', 'Gender'],
                         ['3662e1bd-290a-3563-a7a2-a797b746c4a2', '2018-10-10 07:14:23 UTC', '2018-02-01 00:00:00 UTC', 'PHC Foo', 'b4c3c8ac-a3a9-30fd-ace2-4ebf877aac34', '66', 'female']],
      'blood_pressures.csv' => [['Id', 'Patient', 'Created At', 'Bp Date', 'Facility Name', 'User', 'Bp Systolic', 'Bp Diastolic'],
                                ['f7feef77-3131-31d5-b2d7-31d22a1f0f4b', 'd1eeff8e-638a-36a9-9cfc-359bbe7205d2', '2018-10-10 07:15:09 UTC', '2018-09-26 00:00:00 UTC', 'PHC Foo', '1c43a6ab-5013-3efc-922c-36b2e9ad9393', '154', '86']],
      'medicines.csv' => [['Id', 'Patient', 'Created At', 'Facility Name', 'User', 'Medicine Name', 'Dosage'],
                          ['0f5caad4-06d7-3176-a96e-f56a6deca6ed', '3269c362-0400-3881-9bba-010d2f22b75a', '2018-10-30 10:18:59 UTC', 'CHC Bar', '1c43a6ab-5013-3efc-922c-36b2e9ad9393', 'Amlodipine', '5MG']],
      'appointments.csv' => [['Id', 'Patient', 'Created At', 'Facility Name', 'User', 'Scheduled Date', 'Status', 'Agreed To Visit', 'Remind On'],
                             ['8a0522dd-3311-35b5-8737-e82022fcb8a7', '82431b83-d4fa-39ad-acc6-0362aa50a0f4', '2019-04-02 08:43:01 UTC', 'SDH Quux', 'b81eebcf-19ba-387a-9502-98c02b50f893', '2019-01-26', 'scheduled', 'Unavailable', 'Unavailable']],
      'sms_reminders.csv' => [['Id', 'Appointment', 'Patient', 'User', 'Created At', 'Communication Type', 'Communication Result'],
                              ['620ad47d-ed78-4026-beef-6df8eb46c389', '8a0522dd-3311-35b5-8737-e82022fcb8a7', '8a0522dd-3311-35b5-8737-e82022fcb8a7', 'b4c3c8ac-a3a9-30fd-ace2-4ebf877aac34', '2018-10-10 07:14:23 UTC', 'missed_visit_sms_reminder', 'successful']],
      'phone_calls.csv' => [['Id', 'Created At', 'Result', 'Duration', 'Start Time', 'End Time'],
                            ['f822f310-ee82-406c-9cac-0c4de08dbcc5', '2018-10-10 07:14:23 UTC', 'canceled', '21', 'Thu, 23 May 2019 08:55:31 UTC +00:00', 'Thu, 23 May 2019 08:55:51 UTC +00:00']]
    }
  }
  let(:sent_email) { ActionMailer::Base.deliveries.last }

  before do
    ActiveJob::Base.queue_adapter = :test
  end

  it 'anonymised data mailer job is created' do
    expect {
      AnonymizedDataDownloadMailer.with(recipient_name: recipient_name,
                                        recipient_email: recipient_email,
                                        anonymized_data: empty_attachment_data)
        .mail_anonymized_data.deliver_later
    }.to have_enqueued_job.on_queue('mailers')
  end

  it 'email with anonymised data attachments is sent' do
    expect {
      perform_enqueued_jobs do
        AnonymizedDataDownloadMailer.with(recipient_name: recipient_name,
                                          recipient_email: recipient_email,
                                          anonymized_data: empty_attachment_data)
          .mail_anonymized_data.deliver_later
      end
    }.to change { ActionMailer::Base.deliveries.size }.by(1)
  end

  describe 'email with anonymised data attachments has the correct data' do
    before(:each) do
      perform_enqueued_jobs do
        AnonymizedDataDownloadMailer.with(recipient_name: recipient_name,
                                          recipient_email: recipient_email,
                                          anonymized_data: attachment_data)
          .mail_anonymized_data.deliver_later
      end
    end

    context 'sender and recipient data' do
      it 'should have the correct sender and recipient email' do
        expect(sent_email.from[0]).to eq sender_email
        expect(sent_email.to[0]).to eq recipient_email
      end
    end

    context 'attachment data' do
      it 'should have the correct number of attachments' do
        expect(sent_email.attachments.size).to eq attachment_file_names.size
      end

      it 'should have all the attachments files' do
        attachment_file_names.each do |file|
          sent_email.attachments.include?(file)
        end
      end
    end
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end
end
