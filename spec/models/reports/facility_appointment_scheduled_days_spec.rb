require "rails_helper"

RSpec.describe Reports::FacilityAppointmentScheduledDays, {type: :model, reporting_spec: true} do
  around do |example|
    # This is in the style of ReportingHelpers::freeze_time_for_reporting_specs.
    # Since this view only keeps the last 6 months of data, the date cannot be a
    # fixed point in time like the spec helper.
    Timecop.freeze("#{Date.today.end_of_month.to_s} 23:00 IST") do
      example.run
    end
  end

  it "buckets and counts appointments by the number of days between creation date and scheduled date" do
    facility = create(:facility)
    _appointment_scheduled_0_to_14_days = create(:appointment, facility: facility, scheduled_date: 10.days.from_now, device_created_at: Time.current)
    _appointment_scheduled_15_to_30_days = create(:appointment, facility: facility, scheduled_date: 16.days.from_now, device_created_at: Time.current)
    _appointment_scheduled_31_to_60_days = create(:appointment, facility: facility, scheduled_date: 36.days.from_now, device_created_at: Time.current)
    _appointment_scheduled_more_than_60_days = create(:appointment, facility: facility, scheduled_date: 70.days.from_now, device_created_at: Time.current)

    RefreshReportingViews.new.refresh_v2

    expect(described_class.find_by(month_date: Period.current, facility: facility).appts_scheduled_0_to_14_days).to eq 1
    expect(described_class.find_by(month_date: Period.current, facility: facility).appts_scheduled_15_to_30_days).to eq 1
    expect(described_class.find_by(month_date: Period.current, facility: facility).appts_scheduled_31_to_60_days).to eq 1
    expect(described_class.find_by(month_date: Period.current, facility: facility).appts_scheduled_more_than_60_days).to eq 1
    expect(described_class.find_by(month_date: Period.current, facility: facility).total_appts_scheduled).to eq 4
  end

  it "buckets and counts appointments by the number of days between creation date and scheduled date at a facility per month" do
    facility = create(:facility)
    _appointment_created_today = create(:appointment, facility: facility, scheduled_date: 10.days.from_now, device_created_at: Time.current)
    _appointment_created_1_month_ago = create(:appointment, facility: facility, scheduled_date: Date.today, device_created_at: 1.month.ago)
    _appointment_created_2_month_ago = create(:appointment, facility: facility, scheduled_date: Date.today, device_created_at: 2.month.ago)

    RefreshReportingViews.new.refresh_v2

    expect(described_class.find_by(month_date: Period.current, facility: facility).appts_scheduled_0_to_14_days).to eq 1
    expect(described_class.find_by(month_date: Period.month(1.month.ago), facility: facility).appts_scheduled_31_to_60_days).to eq 1
    expect(described_class.find_by(month_date: Period.month(2.month.ago), facility: facility).appts_scheduled_more_than_60_days).to eq 1
  end

  it "considers only the latest appointment of a patient in a month" do
    facility = create(:facility)
    patient = create(:patient, assigned_facility: facility)
    scheduled_days = 10.days
    first_appointment_date = 12.days.ago
    second_appointment_date = 11.days.ago
    third_appointment_date = 10.days.ago
    create(:appointment,
           facility: facility,
           patient: patient,
           scheduled_date: first_appointment_date + scheduled_days,
           device_created_at: first_appointment_date)
    create(:appointment,
           facility: facility,
           patient: patient,
           scheduled_date: second_appointment_date + scheduled_days,
           device_created_at: second_appointment_date)
    create(:appointment,
           facility: facility,
           patient: patient,
           scheduled_date: third_appointment_date + scheduled_days,
           device_created_at: third_appointment_date)
    create(:appointment, facility: facility, patient: patient, scheduled_date: Date.today, device_created_at: 1.month.ago)

    RefreshReportingViews.new.refresh_v2

    expect(described_class.find_by(month_date: Period.current, facility: facility).appts_scheduled_0_to_14_days).to eq 1
    expect(described_class.find_by(month_date: Period.month(1.month.ago), facility: facility).appts_scheduled_31_to_60_days).to eq 1
  end

  it "considers only last 6 months of appointments" do
    facility = create(:facility)
    patient = create(:patient, assigned_facility: facility)
    _appointment_created_today = create(:appointment, facility: facility, patient: patient, scheduled_date: 11.days.from_now, device_created_at: Time.current)
    _appointment_created_6_month_ago = create(:appointment, facility: facility, patient: patient, scheduled_date: Date.today, device_created_at: 6.month.ago)
    _appointment_created_2_month_ago = create(:appointment, facility: facility, patient: patient, scheduled_date: Date.today, device_created_at: 7.month.ago)

    RefreshReportingViews.new.refresh_v2

    expect(described_class.find_by(month_date: Period.current, facility: facility).appts_scheduled_0_to_14_days).to eq 1
    expect(described_class.find_by(month_date: Period.month(6.month.ago), facility: facility).appts_scheduled_more_than_60_days).to eq 1
    expect(described_class.find_by(month_date: Period.month(7.month.ago), facility: facility)).to be_nil
  end

  it "includes only appointments where scheduled date is after creation date" do
    facility = create(:facility)
    patient = create(:patient, assigned_facility: facility)
    _appointment_created_today = create(:appointment, facility: facility, patient: patient, scheduled_date: Date.yesterday, device_created_at: Time.current)
    _appointment_created_1_month_ago = create(:appointment, facility: facility, patient: patient, scheduled_date: Date.today, device_created_at: 1.month.ago)

    RefreshReportingViews.new.refresh_v2

    expect(described_class.find_by(month_date: Period.current, facility: facility)).to be_nil
    expect(described_class.find_by(month_date: Period.month(1.month.ago), facility: facility).appts_scheduled_31_to_60_days).to eq 1
  end
end
