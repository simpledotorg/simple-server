require "rails_helper"

RSpec.describe AnonymizedDataDownloadMailer, type: :mailer do
  include ActiveJob::TestHelper
  let(:sender_email) { "help@simple.org" }
  let(:recipient_name) { "Example User" }
  let(:recipient_email) { "user@example.com" }
  let(:attachment_file_names) do
    %w[patients.csv blood_pressures.csv medicines.csv appointments.csv
      sms_reminders.csv phone_calls.csv]
  end
  let(:empty_attachment_data) { {} }
  let(:attachment_data) { JSON.parse(File.read("spec/support/fixtures/anonymised_attachment_data.json")) }
  let(:sent_email) { ActionMailer::Base.deliveries.last }

  before do
    ActiveJob::Base.queue_adapter = :test
  end

  it "anonymised data mailer job is created" do
    expect {
      AnonymizedDataDownloadMailer.with(recipient_name: recipient_name,
                                        recipient_email: recipient_email,
                                        anonymized_data: empty_attachment_data)
        .mail_anonymized_data.deliver_later
    }.to have_enqueued_job.on_queue("mailers")
  end

  it "email with anonymised data attachments is sent" do
    expect {
      perform_enqueued_jobs do
        AnonymizedDataDownloadMailer.with(recipient_name: recipient_name,
                                          recipient_email: recipient_email,
                                          anonymized_data: empty_attachment_data,
                                          resource: {district_name: "Sample District",
                                                     facilities: ["Sample Facility"]})
          .mail_anonymized_data.deliver_later
      end
    }.to change { ActionMailer::Base.deliveries.size }.by(1)
  end

  describe "email with anonymised data attachments has the correct data" do
    before(:each) do
      perform_enqueued_jobs do
        AnonymizedDataDownloadMailer.with(recipient_name: recipient_name,
                                          recipient_email: recipient_email,
                                          anonymized_data: attachment_data,
                                          resource: {district_name: "Sample District",
                                                     facilities: ["Sample Facility"]})
          .mail_anonymized_data.deliver_later
      end
    end

    context "sender and recipient data" do
      it "should have the correct sender and recipient email" do
        expect(sent_email.from[0]).to eq sender_email
        expect(sent_email.to[0]).to eq recipient_email
      end
    end

    context "attachment data" do
      it "should have the correct number of attachments" do
        expect(sent_email.attachments.size).to eq attachment_file_names.size
      end

      it "should have all the attachments files" do
        received_attachment_data_file_names = sent_email.attachments.map(&:filename)

        received_attachment_data_file_names.each do |file_name|
          attachment_file_names.include?(file_name)
        end
      end
    end

    it "should have the correct data in the attachment files" do
      received_attachment_data = sent_email.attachments

      received_attachment_data.each do |attachment|
        expect(attachment.body.decoded).to eq attachment_data[attachment.filename].flatten.join
      end
    end
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end
end
