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
  let!(:patients) { create_list(:patient, 6, registration_facility: facility_1, registration_user: user_1) }
  let!(:teleconsultation_requests_only) { patients.take(3).each { |patient| create(:teleconsultation, facility: facility_1, patient: patient, requester: user_1, requested_medical_officer: user_2, medical_officer: user_2, device_created_at: Date.parse("2020-08-04").beginning_of_day, recorded_at: nil, requester_completion_status: "no") } }
  let!(:teleconsultation_requests_marked_complete) { patients.slice(3, 2).each { |patient| create(:teleconsultation, facility: facility_1, patient: patient, requester: user_1, requested_medical_officer: user_2, medical_officer: user_2, device_created_at: Date.parse("2020-08-04").beginning_of_day, requester_completion_status: "yes", recorded_at: nil) } }
  let!(:teleconsultation_mo_logged_record) { create(:teleconsultation, facility: facility_1, patient: patients.last, requester: user_1, requested_medical_officer: user_2, medical_officer: user_2, device_created_at: Date.parse("2020-08-04").beginning_of_day) }

  before do
    allow(Flipper).to receive(:enabled?).with(:weekly_telemed_report).and_return(true)
    allow(ENV).to receive(:fetch).with("TELEMED_REPORT_EMAILS").and_return("test@example.com")
    allow(ENV).to receive(:fetch).with("MIXPANEL_API_SECRET").and_return("fake_api_secret")
    allow_any_instance_of(described_class).to receive(:fetch_mixpanel_data).and_return(File.read(file_path))
    allow_any_instance_of(ActionMailer::MessageDelivery).to receive(:deliver_later)
  end

  context ".generate" do
    it "emails a report file" do
      report_data = [["", "", "", "", "", "", "", "Between #{period_start.strftime("%d-%b-%Y")} and #{period_end.strftime("%d-%b-%Y")}", "", "", "", "", ""],
        ["State", "District", "Facility", "Facilities with telemedicine", "HWCs & SCs with telemedicine", "Users of telemedicine", "", "Patients who visited", "Patients with High BP", "Patients with High Blood Sugar", "Patients with High BP or Sugar", "Teleconsult - Total Button Clicks", "Teleconsult - Requests (new version)", "Teleconsult - Records logged by MOs (new version)", "Teleconsult - Requests marked 'completed' (new version)", "Teleconsult requests percentage"],
        [facility_1.state, "", "", 10, 1, 1, "", 2, 2, 0, 2, 10, 6, 1, 3, "500%"],
        ["", facility_1.district, "", 10, 1, 1, "", 2, 2, 0, 2, 10, 6, 1, 3, "500%"],
        [],
        [],
        ["", "", "", "", "", "", "", "Between #{period_start.strftime("%d-%b-%Y")} and #{period_end.strftime("%d-%b-%Y")}", "", "", "", "", ""],
        ["State", "District", "Facility", "Facilities with telemedicine", "HWCs & SCs with telemedicine", "Users of telemedicine", "", "Patients who visited", "Patients with High BP", "Patients with High Blood Sugar", "Patients with High BP or Sugar", "Teleconsult - Total Button Clicks", "Teleconsult - Requests (new version)", "Teleconsult - Records logged by MOs (new version)", "Teleconsult - Requests marked 'completed' (new version)", "Teleconsult requests percentage"],
        [facility_1.state, "", "", 10, 1, 1, "", 2, 2, 0, 2, 10, 6, 1, 3, "500%"],
        ["", facility_1.district, "", 10, 1, 1, "", 2, 2, 0, 2, 10, 6, 1, 3, "500%"],
        ["", "", facility_1.name, "", "", 1, "", 2, 2, 0, 2, "", 6, 1, 3, ""],
        [],
        [],
        ["Date", "Unique users", "Total TC requests"],
        ["04-Aug-2020", 2, 6],
        ["06-Aug-2020", 1, 1],
        ["07-Aug-2020", 1, 2],
        ["08-Aug-2020", 1, 1]]

      expect(CSV).to receive(:generate).and_call_original
      expect(TelemedReportMailer).to receive(:email_report).and_call_original

      report = TelemedicineReports.new(period_start, period_end)
      report.generate

      expect(report.report_array).to match_array(report_data)
    end
  end
end
