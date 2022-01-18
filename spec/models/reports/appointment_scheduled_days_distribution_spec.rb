require "rails_helper"

RSpec.describe Reports::AppointmentScheduledDaysDistribution, {type: :model, reporting_spec: true} do
  it "buckets and counts appointments by the number of days between creation date and scheduled date" do
    # Need to create and assert these specs in the last six months,
    # since the materialized view skips any data older than six months (relative to db time)
    facility = create(:facility)
    _appointment_scheduled_0_to_14_days = create(:appointment, facility: facility, scheduled_date: 10.days.from_now, device_created_at: Date.today)
    _appointment_scheduled_15_to_30_days = create(:appointment, facility: facility, scheduled_date: 16.days.from_now, device_created_at: Date.today)
    _appointment_scheduled_31_to_60_days = create(:appointment, facility: facility, scheduled_date: 36.days.from_now, device_created_at: Date.today)
    _appointment_scheduled_more_than_60_days = create(:appointment, facility: facility, scheduled_date: 70.days.from_now, device_created_at: Date.today)

    RefreshReportingViews.new.refresh_v2

    expect(described_class.find_by(month_date: Period.current, facility: facility).appts_scheduled_0_to_14_days).to eq 1
    expect(described_class.find_by(month_date: Period.current, facility: facility).appts_scheduled_15_to_30_days).to eq 1
    expect(described_class.find_by(month_date: Period.current, facility: facility).appts_scheduled_31_to_60_days).to eq 1
    expect(described_class.find_by(month_date: Period.current, facility: facility).appts_scheduled_more_than_60_days).to eq 1
    expect(described_class.find_by(month_date: Period.current, facility: facility).total_appts_scheduled).to eq 4
  end

  it "buckets and counts appointments by the number of days between creation date and scheduled date at a facility per month" do
    facility = create(:facility)
    _appointment_created_today = create(:appointment, facility: facility, scheduled_date: 10.days.from_now, device_created_at: Date.today)
    _appointment_created_1_month_ago = create(:appointment, facility: facility, scheduled_date: Date.today, device_created_at: 1.month.ago)
    _appointment_created_2_month_ago = create(:appointment, facility: facility, scheduled_date: Date.today, device_created_at: 2.month.ago)

    RefreshReportingViews.new.refresh_v2

    expect(described_class.find_by(month_date: Period.current, facility: facility).appts_scheduled_0_to_14_days).to eq 1
    expect(described_class.find_by(month_date: Period.month(1.month.ago), facility: facility).appts_scheduled_31_to_60_days).to eq 1
    expect(described_class.find_by(month_date: Period.month(2.month.ago), facility: facility).appts_scheduled_more_than_60_days).to eq 1
  end
end
