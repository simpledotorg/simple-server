require "rails_helper"
require_relative "./experiment_data_examples.rb"

RSpec.describe Experimentation::DataExportWorker, type: :model do
  describe "#perform" do
    include_context "active experiment data"

    it "exports accurate data in the expected format" do
      mail_double = double
      recipient_email_address = "person@example.com"
      email_params = {
        to: recipient_email_address,
        subject: "Experiment data export: #{@experiment.name}",
        content_type: "multipart/mixed",
        body: "Please see attached CSV."
      }
      attachment_data = {
        mime_type: "text/csv",
        content: "blah"
      }

      email_double = double("email")
      allow(email_double).to receive(:attachments).and_return({})
      mailer = instance_double(ApplicationMailer, mail: email_double)
      allow(ApplicationMailer).to receive(:new).and_return(mailer)

      expect(email_double).to receive(:attachments)
      expect(email_double).to receive(:deliver)

      described_class.perform_async(@experiment.name, recipient_email_address)
      described_class.drain
    end
  end
end
