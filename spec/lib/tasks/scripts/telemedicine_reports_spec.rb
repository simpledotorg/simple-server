require "rails_helper"
require "tasks/scripts/telemedicine_reports"

RSpec.describe TelemedicineReports do
  let!(:file_path) { "spec/fixtures/files/telemed_report_input.csv" }
  let!(:invalid_file_path) { "spec/fixtures/files/invalid_file_path.csv" }
  let!(:user) { create(:user, id: "31f4b6c4-6172-499a-95e1-4cea84ec373a") }

  context ".parse_mixpanel" do
    it "should fail if you give it a invalid file path" do
      expect { TelemedicineReports.parse_mixpanel(invalid_file_path) }
        .to raise_error(/No such file or directory/)
    end

    it "should parse a valid mixpanel csv" do
      expect(TelemedicineReports.parse_mixpanel(file_path).size).to eq(141)
    end
  end

  context ".generate_report" do
    it "generates a report file" do
      mixpanel_data = TelemedicineReports.parse_mixpanel(file_path)
      period_start = Date.parse("2020-08-03").beginning_of_day
      period_end = Date.parse("2020-08-09").end_of_day

      report_file_path = "telemedicine_report_03_Aug_to_09_Aug.csv"

      allow(CSV).to receive(:open).with(report_file_path, "w")
      TelemedicineReports.generate_report(mixpanel_data, period_start, period_end)
    end
  end
end
