require "rails_helper"
require_relative Rails.root.join("spec/support/experiment_data_examples.rb")

RSpec.describe ExperimentResultsMailer, type: :model do
  describe "#mail_csv" do
    it "formats the email and attachment correctly" do
      recipient_email_address = "person@example.com"
      experiment_name = "current_patient"
      filename = "current_patient.csv"

      csv_file = CSV.generate(headers: true) do |csv|
        csv << ["column 1", "column 2"]
        csv << ["facts", "figures"]
      end
      results_service_double = instance_double(Experimentation::Results, as_csv: csv_file)
      allow(Experimentation::Results).to receive(:new).and_return(results_service_double)

      expect_any_instance_of(Mail::Message).to receive(:deliver)

      service = described_class.new(experiment_name, recipient_email_address)
      mailer = service.mailer
      service.mail_csv
      attachment = mailer.mail.attachments.first

      expect(attachment.filename).to eq(filename)
      # activemailer adds additional carriage returns, so you can't compare directly against csv_file
      expect(attachment.body.to_s).to eq("column 1,column 2\r\nfacts,figures\r\n")
      expect(mailer.mail.to).to eq([recipient_email_address])
      expect(mailer.mail.subject).to eq("Experiment data export: #{experiment_name}")
      expect(mailer.mail.body.to_s).to eq("Please see attached CSV.")
    end
  end
end
