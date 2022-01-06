# frozen_string_literal: true

require "rails_helper"

RSpec.describe PatientListDownloadMailer, type: :mailer do
  describe "#patient_list" do
    let(:csv_content) { "This is a test csv" }
    let(:recipient_email) { "test@simple.org" }
    let(:mail) {
      described_class.patient_list(
        recipient_email,
        "facility_group",
        "Bhandara",
        csv_content
      )
    }

    it "sends an email to the recipient" do
      expect(mail.to.first).to eq recipient_email
    end

    it "sends a zip archive in the attachment" do
      attachment = mail.attachments.first
      expect(attachment.content_type).to eq "application/zip"
      expect(attachment.filename).to eq "patient-list_facility_group_Bhandara_#{I18n.l(Date.current)}.zip"
    end

    it "compresses the csv in a valid zip archive as attachment" do
      attachment = mail.attachments.first

      Zip::InputStream.open(StringIO.new(attachment.body.raw_source)) do |io|
        entry = io.get_next_entry

        expect(entry.name).to eq "patient-list_facility_group_Bhandara_#{I18n.l(Date.current)}.csv"
        expect(io.read).to eq csv_content
      end
    end
  end
end
