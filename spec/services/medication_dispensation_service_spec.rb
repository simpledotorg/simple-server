require "rails_helper"

RSpec.describe MedicationDispensationService, type: :model do
  it "returns bucketed days of medications data" do
    facility = create(:facility)
    period = Period.current
    _patient = create(:patient, assigned_facility: facility, recorded_at: 1.year.ago)
    _appointment_created_today = create(:appointment, facility: facility, scheduled_date: 10.days.from_now, device_created_at: Date.today)
    _appointment_created_1_month_ago = create(:appointment, facility: facility, scheduled_date: Date.today, device_created_at: 1.month.ago)
    _appointment_created_2_month_ago = create(:appointment, facility: facility, scheduled_date: Date.today, device_created_at: 2.month.ago)

    RefreshReportingViews.new.refresh_v2

    medications_dispensation_service = MedicationDispensationService.new(region: facility, period: period)
    last_3_months = (Period.month(2.months.ago)..Period.current).to_a
    expected_data_structure = {
      "0 - 14 days" => {color: "#BD3838",
                        counts: {last_3_months[0] => 0, last_3_months[1] => 0, last_3_months[2] => 1},
                        totals: {last_3_months[0] => 1, last_3_months[1] => 1, last_3_months[2] => 1},
                        percentages: {last_3_months[0] => 0, last_3_months[1] => 0, last_3_months[2] => 100}},
      "15 - 30 days" => {color: "#E77D27",
                         counts: {last_3_months[0] => 0, last_3_months[1] => 0, last_3_months[2] => 0},
                         totals: {last_3_months[0] => 1, last_3_months[1] => 1, last_3_months[2] => 1},
                         percentages: {last_3_months[0] => 0, last_3_months[1] => 0, last_3_months[2] => 0}},
      "31 - 60 days" => {color: "#729C26",
                         counts: {last_3_months[0] => 0, last_3_months[1] => 1, last_3_months[2] => 0},
                         totals: {last_3_months[0] => 1, last_3_months[1] => 1, last_3_months[2] => 1},
                         percentages: {last_3_months[0] => 0, last_3_months[1] => 100, last_3_months[2] => 0}},
      "60+ days" => {color: "#007AA6",
                     counts: {last_3_months[0] => 1, last_3_months[1] => 0, last_3_months[2] => 0},
                     totals: {last_3_months[0] => 1, last_3_months[1] => 1, last_3_months[2] => 1},
                     percentages: {last_3_months[0] => 100, last_3_months[1] => 0, last_3_months[2] => 0}}
    }
    expect(medications_dispensation_service.distribution).to eq(expected_data_structure)
  end
end
