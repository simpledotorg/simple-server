require "rails_helper"

RSpec.describe Reports::FacilityAppointmentScheduledDays, {type: :model, reporting_spec: true} do
  around do |example|
    # This is in the style of ReportingHelpers::freeze_time_for_reporting_specs.
    # Since this view only keeps the last 6 months of data, the date cannot be a
    # fixed point in time like the spec helper.
    Timecop.freeze("#{Date.today.end_of_month} 23:00 IST") do
      example.run
    end
  end

  it "includes only follow-up appointments i.e which happened in a month after patient registration" do
    facility = create(:facility)
    follow_up_patient = create(:patient, recorded_at: 1.month.ago, assigned_facility: facility)
    registered_patient = create(:patient, recorded_at: Time.current, assigned_facility: facility)
    create(:appointment, patient: follow_up_patient, facility: facility, scheduled_date: 10.days.from_now, device_created_at: Time.current)
    create(:appointment, patient: registered_patient, facility: facility, scheduled_date: 10.days.from_now, device_created_at: Time.current)

    RefreshReportingViews.new.refresh_v2

    expect(described_class.find_by(month_date: Period.current, facility: facility).appts_scheduled_0_to_14_days).to eq 1
  end

  it "buckets and counts appointments by the number of days between creation date and scheduled date" do
    facility = create(:facility)
    scheduled_dates = [-1.days.from_now,
                       0.days.from_now, 14.days.from_now,
                       15.days.from_now, 31.days.from_now,
                       32.days.from_now, 62.days.from_now,
                       63.days.from_now, 100.days.from_now]

    scheduled_dates.each do |date|
      create(:appointment,
             scheduled_date: date,
             device_created_at: Time.current,
             facility: facility,
             patient: create(:patient, recorded_at: 1.month.ago))
    end

    RefreshReportingViews.new.refresh_v2

    expect(described_class.find_by(month_date: Period.current, facility: facility).appts_scheduled_0_to_14_days).to eq 2
    expect(described_class.find_by(month_date: Period.current, facility: facility).appts_scheduled_15_to_31_days).to eq 2
    expect(described_class.find_by(month_date: Period.current, facility: facility).appts_scheduled_32_to_62_days).to eq 2
    expect(described_class.find_by(month_date: Period.current, facility: facility).appts_scheduled_more_than_62_days).to eq 2
    expect(described_class.find_by(month_date: Period.current, facility: facility).total_appts_scheduled).to eq 8
  end

  it "buckets and counts appointments by the number of days between creation date and scheduled date at a facility per month" do
    facility = create(:facility)
    patient = create(:patient, recorded_at: 3.months.ago)
    _appointment_created_today = create(:appointment, patient: patient, facility: facility, scheduled_date: 10.days.from_now, device_created_at: Time.current)
    _appointment_created_1_month_ago = create(:appointment, patient: patient, facility: facility, scheduled_date: Date.today, device_created_at: 31.days.ago)
    _appointment_created_2_month_ago = create(:appointment, patient: patient, facility: facility, scheduled_date: Date.today, device_created_at: 62.days.ago)

    RefreshReportingViews.new.refresh_v2

    expect(described_class.find_by(month_date: Period.current, facility: facility).appts_scheduled_0_to_14_days).to eq 1
    expect(described_class.find_by(month_date: Period.month(1.month.ago), facility: facility).appts_scheduled_15_to_31_days).to eq 1
    expect(described_class.find_by(month_date: Period.month(2.month.ago), facility: facility).appts_scheduled_32_to_62_days).to eq 1
  end

  it "considers only the latest appointment of a patient in a month" do
    facility = create(:facility)
    patient = create(:patient, recorded_at: 1.months.ago)
    first_appointment_date = 12.days.ago
    second_appointment_date = 11.days.ago
    third_appointment_date = 10.days.ago
    create(:appointment,
      facility: facility,
      patient: patient,
      scheduled_date: first_appointment_date + 10.days,
      device_created_at: first_appointment_date)
    create(:appointment,
      facility: facility,
      patient: patient,
      scheduled_date: second_appointment_date + 35.days,
      device_created_at: second_appointment_date)
    create(:appointment,
      facility: facility,
      patient: patient,
      scheduled_date: third_appointment_date + 70.days,
      device_created_at: third_appointment_date)

    RefreshReportingViews.new.refresh_v2

    expect(described_class.find_by(month_date: Period.current, facility: facility).appts_scheduled_more_than_62_days).to eq 1
  end

  it "considers only last 6 months of appointments" do
    facility = create(:facility)
    patient = create(:patient, recorded_at: 8.months.ago, assigned_facility: facility)
    _appointment_created_today = create(:appointment, facility: facility, patient: patient, scheduled_date: 11.days.from_now, device_created_at: Time.current)
    _appointment_created_6_months_ago = create(:appointment, facility: facility, patient: patient, scheduled_date: Date.today, device_created_at: 6.month.ago)
    _appointment_created_7_months_ago = create(:appointment, facility: facility, patient: patient, scheduled_date: Date.today, device_created_at: 7.month.ago)

    RefreshReportingViews.new.refresh_v2

    expect(described_class.find_by(month_date: Period.current, facility: facility).appts_scheduled_0_to_14_days).to eq 1
    expect(described_class.find_by(month_date: Period.month(6.month.ago), facility: facility).appts_scheduled_more_than_62_days).to eq 1
    expect(described_class.find_by(month_date: Period.month(7.month.ago), facility: facility)).to be_nil
  end

  it "does not include appointments where scheduled date is before creation date" do
    facility = create(:facility)
    create(:appointment,
      facility: facility,
      patient: create(:patient, recorded_at: 1.month.ago),
      scheduled_date: Date.yesterday,
      device_created_at: Time.current)

    RefreshReportingViews.new.refresh_v2

    expect(described_class.find_by(month_date: Period.current, facility: facility)).to be_nil
  end

  it "includes only appointments where scheduled date is on or after creation date " do
    facility = create(:facility)
    create(:appointment,
      facility: facility,
      patient: create(:patient, recorded_at: 1.month.ago),
      scheduled_date: Date.yesterday,
      device_created_at: Time.current)
    create(:appointment,
      facility: facility,
      patient: create(:patient, recorded_at: 1.month.ago),
      scheduled_date: Date.today,
      device_created_at: Time.current)
    create(:appointment,
      facility: facility,
      patient: create(:patient, recorded_at: 1.month.ago),
      scheduled_date: Date.tomorrow,
      device_created_at: Time.current)

    RefreshReportingViews.new.refresh_v2

    expect(described_class.find_by(month_date: Period.current, facility: facility).appts_scheduled_0_to_14_days).to eq 2
  end

  it "does not include soft-deleted patients or appointments" do
    facility = create(:facility)
    deleted_patient = create(:patient, recorded_at: 2.months.ago, assigned_facility: facility, deleted_at: Time.current)
    create(:appointment, facility: facility, patient: deleted_patient)

    _deleted_appointment =
      create(:appointment,
        facility: facility,
        patient: create(:patient, recorded_at: 2.months.ago),
        deleted_at: Time.current)

    RefreshReportingViews.new.refresh_v2

    expect(described_class.find_by(month_date: Period.current, facility: facility)).to be_nil
  end
end
