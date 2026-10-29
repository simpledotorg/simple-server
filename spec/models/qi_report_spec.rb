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

  describe ".enabled?" do
    it "is off unless the country enables it" do
      allow(CountryConfig).to receive(:current).and_return({})
      expect(described_class.enabled?).to be(false)

      allow(CountryConfig).to receive(:current).and_return({qi_reports: {enabled: true}})
      expect(described_class.enabled?).to be(true)
    end

    it "is on for Bangladesh and off for Ethiopia and the other countries" do
      expect(CountryConfig::CONFIGS[:BD][:qi_reports][:enabled]).to be(true)
      expect(CountryConfig::CONFIGS[:ET][:qi_reports][:enabled]).to be(false)
      expect(CountryConfig::CONFIGS[:IN][:qi_reports]).to be_nil
    end
  end

  describe ".settings" do
    it "defaults to district-level reports with Division and District labels" do
      expect(described_class.settings).to include(enabled: false, level: "district", division_label: "Division", place_label: "District")
    end

    it "can be overridden per country" do
      allow(CountryConfig).to receive(:current).and_return({qi_reports: {level: "state", place_label: "Region"}})

      expect(described_class.state_level?).to be(true)
      expect(described_class.settings[:place_label]).to eq("Region")
    end
  end
end
