require "rails_helper"

RSpec.describe MedicationDispensationService, type: :model do
  it "returns bucketed days of medications data" do
    Timecop.freeze("#{Date.today.end_of_month} 23:00 IST") do
      facility = create(:facility)
      period = Period.current
      patient = create(:patient, recorded_at: 1.year.ago)
      _appointment_created_today = create(:appointment, patient: patient, facility: facility, scheduled_date: 10.days.from_now, device_created_at: Date.today)
      _appointment_created_1_month_ago = create(:appointment, patient: patient, facility: facility, scheduled_date: Date.today, device_created_at: 32.days.ago)
      _appointment_created_2_month_ago = create(:appointment, patient: patient, facility: facility, scheduled_date: Date.today, device_created_at: 63.days.ago)

      RefreshReportingViews.refresh_v2

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
        "1 month (15-31 days)" => {color: "#E77D27",
                                   counts: {two_months_ago => 0, one_month_ago => 0, current_month => 0},
                                   totals: {two_months_ago => 1, one_month_ago => 1, current_month => 1},
                                   percentages: {two_months_ago => 0, one_month_ago => 0, current_month => 0}},
        "2 months (32-62 days)" => {color: "#729C26",
                                    counts: {two_months_ago => 0, one_month_ago => 1, current_month => 0},
                                    totals: {two_months_ago => 1, one_month_ago => 1, current_month => 1},
                                    percentages: {two_months_ago => 0, one_month_ago => 100, current_month => 0}},
        ">2 months" => {color: "#007AA6",
                        counts: {two_months_ago => 1, one_month_ago => 0, current_month => 0},
                        totals: {two_months_ago => 1, one_month_ago => 1, current_month => 1},
                        percentages: {two_months_ago => 100, one_month_ago => 0, current_month => 0}}
      }
      expect(medications_dispensation_service.call).to eq(expected_data_structure)
    end
  end
end
