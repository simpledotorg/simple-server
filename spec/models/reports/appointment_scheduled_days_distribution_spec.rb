require "rails_helper"

RSpec.describe Reports::AppointmentScheduledDaysDistribution, {type: :model, reporting_spec: true} do
  describe "total_appts_scheduled" do
    it "computes the total appointments scheduled at the facility per month" do
      # Need to create and assert these specs in the last six months,
      # since the materialized view skips any data older than six months (relative to db time)
      region_district = setup_district_with_facilities
      _appt1 = create(:appointment, facility: region_district[:facility_1])
      _appt2 = create(:appointment, facility: region_district[:facility_1])
      _appt3 = create(:appointment,
        facility: region_district[:facility_2],
        scheduled_date: 10.days.from_now,
        device_created_at: 1.month.ago)
      _appt4 = create(:appointment,
        facility: region_district[:facility_2],
        scheduled_date: 10.days.from_now,
        device_created_at: 2.month.ago)

      RefreshReportingViews.new.refresh_v2

      expect(described_class.find_by(month_date: Period.current, facility: region_district[:facility_1]).total_appts_scheduled).to eq 2
      expect(described_class.find_by(month_date: Period.month(1.month.ago), facility: region_district[:facility_2]).total_appts_scheduled).to eq 1
      expect(described_class.find_by(month_date: Period.month(2.months.ago), facility: region_district[:facility_2]).total_appts_scheduled).to eq 1
    end
  end
end
