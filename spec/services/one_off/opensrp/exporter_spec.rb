require "rails_helper"

describe OneOff::Opensrp::Exporter do
  context "configuration" do
    let(:config_path) { Rails.root.join("tmp", "mock_opensrp_config.yml") }
    let(:the_config) { described_class::Config.new config_path }

    before do
      config_content = <<-YAML
      time_boundaries:
        report_start: 2001-01-01
        report_end: 2002-02-02
      facilities:
        d1dbd3c6-26bb-48e7-aa89-bc8a0b2bf75b:
          name: Health Facility 1
          practitioner_id: 0c375fe8-b38f-484e-aa64-c02750ee183b
          organization_id: d3363aea-66ad-4370-809a-8e4436a4218f
          care_team_id: 1c8100b5-222b-4815-ba4d-3ebde537c6ce
          location_id: ABC01230123
      YAML
      File.write config_path, config_content
    end

    after do
      File.delete(config_path) if File.exist?(config_path)
    end

    it "parses :report_start" do
      expect(the_config.report_start).to eq(Date.parse("2001-01-01"))
    end

    it "parses :report_end" do
      expect(the_config.report_end).to eq(Date.parse("2002-02-02"))
    end

    it "parses :facilities to export" do
      facility_keys = %i[
        care_team_id
        location_id
        name
        organization_id
        practitioner_id
      ]
      expect(the_config.facilities.size).to eq 1
      # This weird quirk is because Hash#first returns an array [key, value]
      facility_spec = the_config.facilities.first.last
      expect(facility_spec[:name]).to eq "Health Facility 1"
      expect(facility_spec.keys.map(&:to_sym)).to match_array(facility_keys)
    end

    it "parses :time_window" do
      expect(the_config.time_window).to eq(the_config.report_start..the_config.report_end)
    end
  end

  describe "initialization" do
    let(:valid_config) { "config.yml" }
    let(:valid_output) { "output.json" }

    it "raises an error for non-YAML config files" do
      expect { described_class.new("config.txt", valid_output) }.to raise_error("Config file should be YAML")
    end

    it "raises an error for non-JSON output files" do
      expect { described_class.new(valid_config, "output.txt") }.to raise_error("Output file should be JSON")
    end

    it "expects config to be YAML, and output to be JSON" do
      allow(described_class::Config).to receive(:new)
      nulloger = ActiveSupport::Logger.new("/dev/null")
      expect { described_class.new(valid_config, valid_output, logger: nulloger) }.not_to raise_error
    end
  end

  describe "#call!" do
    # TODO: Setting this up is so involved!!!
    let(:facility_id) { "e120e6c6-141a-4c86-9cab-4d3871ff5fe7" }
    let(:config_path) { Rails.root.join("tmp", "test_config.yml") }
    let(:output_path) { Rails.root.join("tmp", "test_output.json") }

    let(:patient) { create(:patient) }
  end
end
