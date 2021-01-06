require "rails_helper"

RSpec.describe PatientListDownloadMailer, type: :mailer do
  describe "#patient_list" do
    let(:csv_content) { "This is a test csv" }
    let!(:mail) {
      described_class.patient_list(
        "test@simple.org",
        "facility_group",
        "Bhandara",
        csv_content
      )
    }

    it "sends a compresses the csv into a valid zip file and sends as attachment" do
      attachment = mail.attachments.first
      expect(attachment.content_type).to eq "application/zip"
      expect(attachment.filename).to eq "patient-list_facility_group_Bhandara_#{I18n.l(Date.current)}.csv.zip"

      Zip::InputStream.open(StringIO.new(attachment.body.raw_source)) do |io|
        entry = io.get_next_entry

        expect(entry.name).to eq "patient-list_facility_group_Bhandara_#{I18n.l(Date.current)}.csv"
        expect(io.read).to eq csv_content
      end
    end
  end
end
