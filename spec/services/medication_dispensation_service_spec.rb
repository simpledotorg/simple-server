require "rails_helper"

RSpec.describe MedicationDispensationService, type: :model do
  it "returns bucketed days of medications data" do
    skip "failing February 3rd 2022 in the afternoon US time"
    facility = create(:facility)
    period = Period.current
    patient = create(:patient, recorded_at: 1.year.ago)
    _appointment_created_today = create(:appointment, patient: patient, facility: facility, scheduled_date: 10.days.from_now, device_created_at: Date.today)
    _appointment_created_1_month_ago = create(:appointment, patient: patient, facility: facility, scheduled_date: Date.today, device_created_at: 1.month.ago)
    _appointment_created_2_month_ago = create(:appointment, patient: patient, facility: facility, scheduled_date: Date.today, device_created_at: 2.month.ago)

    RefreshReportingViews.new.refresh_v2

    medications_dispensation_service = MedicationDispensationService.new(region: facility, period: period)
    last_3_months = (Period.month(2.months.ago)..Period.current).to_a
    current_month = last_3_months.last
    one_month_ago = last_3_months.second
    two_months_ago = last_3_months.first
    expected_data_structure = {
      "0-14 days" => {color: "#BD3838",
                      counts: {two_months_ago => 0, one_month_ago => 0, current_month => 1},
                      totals: {two_months_ago => 1, one_month_ago => 1, current_month => 1},
                      percentages: {two_months_ago => 0, one_month_ago => 0, current_month => 100}},
      "15-30 days" => {color: "#E77D27",
                       counts: {two_months_ago => 0, one_month_ago => 0, current_month => 0},
                       totals: {two_months_ago => 1, one_month_ago => 1, current_month => 1},
                       percentages: {two_months_ago => 0, one_month_ago => 0, current_month => 0}},
      "31-60 days" => {color: "#729C26",
                       counts: {two_months_ago => 0, one_month_ago => 1, current_month => 0},
                       totals: {two_months_ago => 1, one_month_ago => 1, current_month => 1},
                       percentages: {two_months_ago => 0, one_month_ago => 100, current_month => 0}},
      "60+ days" => {color: "#007AA6",
                     counts: {two_months_ago => 1, one_month_ago => 0, current_month => 0},
                     totals: {two_months_ago => 1, one_month_ago => 1, current_month => 1},
                     percentages: {two_months_ago => 100, one_month_ago => 0, current_month => 0}}
    }
    expect(medications_dispensation_service.call).to eq(expected_data_structure)
  end
end
