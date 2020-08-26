require "rails_helper"
require "tasks/scripts/telemedicine_reports"

RSpec.describe TelemedicineReports do
  let!(:file_path) { "spec/fixtures/files/telemed_report_input.csv" }
  let!(:period_start) { Date.parse("2020-08-03").beginning_of_day }
  let!(:period_end) { Date.parse("2020-08-09").end_of_day }
  let!(:facility_1) { create(:facility, enable_teleconsultation: true, facility_type: "HWC") }
  let!(:facility_2) { create(:facility, enable_teleconsultation: true, facility_type: "DH") }
  let!(:user_1) { create(:user, id: "31f4b6c4-6172-499a-95e1-aaaaaaaaaaaa", registration_facility: facility_1) }
  let!(:user_2) { create(:user, id: "31f4b6c4-6172-499a-95e1-bbbbbbbbbbbb", registration_facility: facility_2) }
  let!(:high_bps) { create_list(:blood_pressure, 2, :hypertensive, :with_encounter, facility: facility_1, user: user_1, recorded_at: period_start + 1.day) }
  let!(:high_bps_2) { create_list(:blood_pressure, 2, :with_encounter, :hypertensive, facility: facility_2, user: user_2, recorded_at: period_start + 1.day) }
  context ".parse_mixpanel" do
    it "should fail if you give it a invalid file path" do
      invalid_file_path = "spec/fixtures/files/invalid_file_path.csv"

      report = TelemedicineReports.new(invalid_file_path, period_start, period_end)
      expect { report.generate }.to raise_error(/No such file or directory/)
    end

    it "should parse a valid mixpanel csv" do
      report = TelemedicineReports.new(file_path, period_start, period_end)
      report.generate
      expect(report.mixpanel_data[:hydrated].size).to eq(6)
    end
  end

  context ".generate_report" do
    it "generates a report file" do
      filename = "telemedicine_report_03_Aug_to_09_Aug.csv"
      # This result is dependent on the factories, could become flaky if the factories change significantly.
      # We should drop these specs once we switch over to the Telemed MVP
      report_data = [["", "", "", "", "", "", "", "Between #{period_start.strftime("%d %b %Y")} and #{period_end.strftime("%d %b %Y")}", "", "", "", "", ""],
        ["State", "District", "Facility", "Facilities with telemedicine", "HWCs & SCs with telemedicine", "Users of telemedicine", "", "Patients who visited", "Patients with High BP", "Patients with High Blood Sugar", "Patients with High BP or Sugar", "Teleconsult Button Clicks", "Teleconsult requests percentage"],
        [facility_1.state, "", "", 10, 1, 1, "", 2, 2, 0, 2, 10, "500%"],
        ["", facility_1.district, "", 10, 1, 1, "", 2, 2, 0, 2, 10, "500%"],
        [],
        [],
        ["", "", "", "", "", "", "", "Between #{period_start.strftime("%d %b %Y")} and #{period_end.strftime("%d %b %Y")}", "", "", "", "", ""],
        ["State", "District", "Facility", "Facilities with telemedicine", "HWCs & SCs with telemedicine", "Users of telemedicine", "", "Patients who visited", "Patients with High BP", "Patients with High Blood Sugar", "Patients with High BP or Sugar", "Teleconsult Button Clicks", "Teleconsult requests percentage"],
        [facility_1.state, "", "", 10, 1, 1, "", 2, 2, 0, 2, 10, "500%"],
        ["", facility_1.district, "", 10, 1, 1, "", 2, 2, 0, 2, 10, "500%"],
        ["", "", facility_1.name, "", "", 1, "", 2, 2, 0, 2, "", ""],
        [],
        [],
        ["Date", "Unique users", "Total TC requests"],
        ["04 Aug 2020", 2, 6],
        ["06 Aug 2020", 1, 1],
        ["07 Aug 2020", 1, 2],
        ["08 Aug 2020", 1, 1]]

      expect(CSV).to receive(:open).with(filename, "w")

      report = TelemedicineReports.new(file_path, period_start, period_end)
      report.generate

      expect(report.report_array).to match_array(report_data)
    end
  end
end
