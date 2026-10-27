require "rails_helper"

RSpec.describe QiReport do
  describe ".parse" do
    it "reads report, district and period from the filename" do
      report = described_class.parse("Titration - Kalutara - Sep 2026.pdf")

      expect(report.report).to eq("Titration")
      expect(report.district).to eq("Kalutara")
      expect(report.period).to eq("Sep 2026")
    end

    it "reads month-to-date filenames" do
      expect(described_class.parse("Titration - Kalutara - 2026-10-27.pdf").period).to eq("2026-10-27")
    end

    it "ignores other files" do
      expect(described_class.parse("notes.txt")).to be_nil
    end
  end

  describe ".visible_to" do
    it "only returns reports for districts the user can view reports for" do
      facility_group = create(:facility_group, name: "Kalutara")
      other = create(:facility_group, name: "Galle")
      admin = create(:admin, :manager, :with_access, resource: facility_group)
      reports = [described_class.parse("Titration - Kalutara - Sep 2026.pdf"),
        described_class.parse("Titration - Galle - Sep 2026.pdf")]
      allow(described_class).to receive(:all).and_return(reports)

      expect(described_class.visible_to(admin).map(&:district)).to eq(["Kalutara"])
      expect(other).to be_present
    end
  end
end
