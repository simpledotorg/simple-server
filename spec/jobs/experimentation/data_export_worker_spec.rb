require "rails_helper"
require_relative Rails.root.join("spec/support/experiment_data_examples.rb")

RSpec.describe Experimentation::DataExportWorker, type: :model do
  describe "#perform" do
    include_context "active experiment data"

    it "sends the email successfully" do
      expect_any_instance_of(Mail::Message).to receive(:deliver)
      described_class.perform_async(@experiment.name, recipient_email_address = "person@example.com")
      described_class.drain
    end

    it "properly formats " do
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
      filename = @experiment.name.gsub(" ", "_") + ".csv"

      email_double = double("email")
      attachments_double = double("attachments")
      mailer = instance_double(ApplicationMailer, mail: email_double)
      allow(ApplicationMailer).to receive(:new).and_return(mailer)
      allow(email_double).to receive(:attachments).and_return(attachments_double)

      expect(attachments_double).to receive(:[]=).with(filename, attachment_data)

      described_class.perform_async(@experiment.name, recipient_email_address)
      described_class.drain
    end
  end
end
