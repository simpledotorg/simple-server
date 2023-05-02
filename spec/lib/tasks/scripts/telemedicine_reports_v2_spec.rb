require "rails_helper"
require "tasks/scripts/telemedicine_reports_v2"

RSpec.describe TelemedicineReportsV2 do
  before do
    allow(Flipper).to receive(:enabled?).with(:automated_telemed_report).and_return(true)
    allow(ENV).to receive(:fetch).with("TELEMED_REPORT_EMAILS").and_return("test@example.com")
    allow_any_instance_of(ActionMailer::MessageDelivery).to receive(:deliver_later)
  end

  context ".generate" do
    it "emails a report file" do
      period_start = Date.parse("2020-08-03").beginning_of_day
      period_end = Date.parse("2020-08-09").end_of_day
      facility_1 = create(:facility, :with_teleconsultation, name: "Facility A", facility_type: "HWC", facility_size: :community)
      facility_2 = create(:facility, :with_teleconsultation, name: "Facility B", facility_type: "DH", facility_size: :large, facility_group: facility_1.facility_group)
      user_1 = create(:user, id: "31f4b6c4-6172-499a-95e1-aaaaaaaaaaaa", registration_facility: facility_1)
      user_2 = create(:user, id: "31f4b6c4-6172-499a-95e1-bbbbbbbbbbbb", registration_facility: facility_2)
      medical_officer = create(:user, id: "31f4b6c4-6172-499a-95e1-cccccccccccc", registration_facility: facility_2)
      _high_bps = create_list(:blood_pressure, 2, :hypertensive, :with_encounter, facility: facility_1, user: user_1, recorded_at: period_start + 1.day)
      _high_bps_2 = create_list(:blood_pressure, 2, :with_encounter, :hypertensive, facility: facility_2, user: medical_officer, recorded_at: period_start + 1.day)
      patients = create_list(:patient, 9, registration_facility: facility_1, registration_user: user_1)
      _teleconsultation_requests_marked_not_complete = patients.take(3).each { |patient| create(:teleconsultation, facility: facility_1, patient: patient, requester: user_1, requested_medical_officer: medical_officer, medical_officer: medical_officer, device_created_at: Date.parse("2020-08-04").beginning_of_day, recorded_at: nil, requester_completion_status: "no") }
      _teleconsultation_requests_marked_complete = patients.slice(3, 2).each { |patient| create(:teleconsultation, facility: facility_1, patient: patient, requester: user_1, requested_medical_officer: medical_officer, medical_officer: medical_officer, device_created_at: Date.parse("2020-08-04").beginning_of_day, requester_completion_status: "yes", recorded_at: nil) }
      _teleconsultation_mo_logged_record = create(:teleconsultation, facility: facility_1, patient: patients.last, requester: user_2, requested_medical_officer: medical_officer, medical_officer: medical_officer, device_created_at: Date.parse("2020-08-04").beginning_of_day)
      _teleconsultation_requests_marked_waiting = patients.slice(5, 2).each { |patient| create(:teleconsultation, facility: facility_2, patient: patient, requester: user_1, requested_medical_officer: medical_officer, medical_officer: medical_officer, device_created_at: Date.parse("2020-08-05").beginning_of_day, requester_completion_status: "waiting", recorded_at: nil) }
      _teleconsultation_requests_not_marked = patients.slice(7, 2).each { |patient| create(:teleconsultation, facility: facility_2, patient: patient, requester: user_1, requested_medical_officer: medical_officer, medical_officer: medical_officer, device_created_at: Date.parse("2020-08-05").beginning_of_day, requester_completion_status: nil, recorded_at: nil) }
      _unmarked_requests_which_should_be_excluded_from_counts = patients.each { |patient| create(:teleconsultation, facility: facility_1, patient: patient, requester: user_2, requested_medical_officer: medical_officer, medical_officer: medical_officer, device_created_at: Date.parse("2020-08-05").beginning_of_day, requester_completion_status: nil, recorded_at: nil) }
      _waiting_requests_which_should_be_excluded_from_counts = patients.slice(3, 2).each { |patient| create(:teleconsultation, facility: facility_2, patient: patient, requester: user_1, requested_medical_officer: medical_officer, medical_officer: medical_officer, device_created_at: Date.parse("2020-08-06").beginning_of_day, requester_completion_status: "waiting", recorded_at: nil) }
      _incomplete_requests_which_should_be_excluded_from_counts = patients.slice(3, 2).each { |patient| create(:teleconsultation, facility: facility_1, patient: patient, requester: user_1, requested_medical_officer: medical_officer, medical_officer: medical_officer, device_created_at: Date.parse("2020-08-06").beginning_of_day, requester_completion_status: "no", recorded_at: nil) }

      report_data = [["", "", "", "", "", "", "", "Between #{period_start.strftime("%d-%b-%Y")} and #{period_end.strftime("%d-%b-%Y")}", "", "", "", "", "", "", "", "", "", ""],
        ["State", "District", "Facility", "Facilities with telemedicine", "Community facilities with telemedicine", "Users of telemedicine", "", "Patients who visited", "Patients with High BP", "Patients with High Blood Sugar", "Patients with High BP or Sugar", "Teleconsult - Requests", "Teleconsult - Records logged by MOs", "Teleconsult - Requests marked completed", "Teleconsult - Requests marked incomplete", "Teleconsult - Requests marked waiting", "Teleconsult - Requests not marked (no completion status set)", "Teleconsult requests percentage"],
        [facility_1.state, "", "", 2, 1, 3, "", 4, 4, 0, 4, 15, 1, 3, 3, 4, 5, "375%"],
        ["", facility_1.district, "", 2, 1, 3, "", 4, 4, 0, 4, 15, 1, 3, 3, 4, 5, "375%"],
        [],
        [],
        ["", "", "", "", "", "", "", "Between #{period_start.strftime("%d-%b-%Y")} and #{period_end.strftime("%d-%b-%Y")}", "", "", "", "", "", "", "", "", "", ""],
        ["State", "District", "Facility", "Facilities with telemedicine", "Community facilities with telemedicine", "Users of telemedicine", "", "Patients who visited", "Patients with High BP", "Patients with High Blood Sugar", "Patients with High BP or Sugar", "Teleconsult - Requests", "Teleconsult - Records logged by MOs", "Teleconsult - Requests marked completed", "Teleconsult - Requests marked incomplete", "Teleconsult - Requests marked waiting", "Teleconsult - Requests not marked (no completion status set)", "Teleconsult requests percentage"],
        [facility_1.state, "", "", 2, 1, 3, "", 4, 4, 0, 4, 15, 1, 3, 3, 4, 5, "375%"],
        ["", facility_1.district, "", 2, 1, 3, "", 4, 4, 0, 4, 15, 1, 3, 3, 4, 5, "375%"],
        ["", "", "Facility A", "", "", 1, "", 2, 2, 0, 2, 9, 1, 3, 3, 0, 3, "450%"],
        ["", "", "Facility B", "", "", 2, "", 2, 2, 0, 2, 6, 0, 0, 0, 4, 2, "300%"],
        [],
        [],
        ["Date", "Unique users", "Total TC requests"],
        ["04-Aug-2020", 2, 6],
        ["05-Aug-2020", 2, 13],
        ["06-Aug-2020", 1, 4]]

      expect(CSV).to receive(:generate).and_call_original
      expect(TelemedReportMailer).to receive(:email_report).and_call_original

      report = TelemedicineReportsV2.new(period_start, period_end)
      report.generate

      expect(report.report_array).to match_array(report_data)
    end
  end
end
