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

  describe "with the real country settings" do
    it "reads Bangladesh's and Ethiopia's settings (stored with string keys) over the defaults" do
      allow(CountryConfig).to receive(:current).and_return(CountryConfig::CONFIGS[:BD])
      expect(described_class.enabled?).to be(true)
      expect(described_class.state_level?).to be(false)
      expect(described_class.settings).to include(division_label: "Division", place_label: "District")

      allow(CountryConfig).to receive(:current).and_return(CountryConfig::CONFIGS[:ET])
      expect(described_class.enabled?).to be(false)
      expect(described_class.state_level?).to be(true)
      expect(described_class.settings).to include(place_label: "Region")
    end
  end

  describe ".script_settings" do
    # keys publish_district_reports.py needs for every report
    let(:report_keys) do
      %w[name place_col month_col numerator_col denominator_col percent_col headline description
        numerator_label denominator_label sentence]
    end

    it "has the settings the report script needs for Bangladesh and Ethiopia" do
      {BD: "district", ET: "region"}.each do |abbreviation, noun|
        allow(CountryConfig).to receive(:current).and_return(CountryConfig::CONFIGS[abbreviation])
        script = described_class.script_settings

        expect(script).to include("place_noun" => noun)
        expect(script["place_list_sql"]).to be_present
        expect(script["reports"].map { |r| r["name"] }).to eq(%w[Titration Statins])
        script["reports"].each do |report|
          expect(report.keys).to include(*report_keys)
          # a report comes either from a Metabase question or from a CSV
          expect(report["card_id"].present? || report["csv"].present?).to be(true)
        end
      end
    end

    it "is not part of the dashboard settings and is nil for countries without it" do
      allow(CountryConfig).to receive(:current).and_return(CountryConfig::CONFIGS[:BD])
      expect(described_class.settings).not_to have_key(:script)

      allow(CountryConfig).to receive(:current).and_return(CountryConfig::CONFIGS[:IN])
      expect(described_class.script_settings).to be_nil
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
