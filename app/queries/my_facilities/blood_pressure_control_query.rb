# frozen_string_literal: true

class MyFacilities::BloodPressureControlQuery
  include QuarterHelper
  include MonthHelper

  def initialize(period: :quarter,
                 quarter: quarter(Time.current),
                 month: Time.current.month,
                 year: Time.current.year,
                 facilities: Facility.all)
    @period = period
    @month = month
    @quarter = quarter
    @year = year
    @facilities = facilities
  end

  def cohort_registrations
    @period == :month ? monthly_registrations : quarterly_registrations
  end

  def cohort_controlled_bps
    @period == :month ? monthly_controlled_bps : quarterly_controlled_bps
  end

  def cohort_uncontrolled_bps
    @period == :month ? monthly_uncontrolled_bps : quarterly_uncontrolled_bps
  end

  def all_time_bps
    LatestBloodPressuresPerPatient
      .where(bp_facility_id: @facilities)
  end

  def all_time_controlled_bps
    all_time_bps
      .where('bp_recorded_at > ?', Date.current - 90.days)
      .where('systolic < 140 AND diastolic < 90')
  end

  private

  def quarterly_registrations
    patients = Patient.where(registration_facility: @facilities)
    previous_cohort = previous_year_and_quarter(@year, @quarter)

    patients.where('recorded_at > ? AND recorded_at <= ?',
                   quarter_start(*previous_cohort),
                   quarter_end(*previous_cohort))
  end

  def quarterly_bps
    cohort_registrations = quarterly_registrations
    LatestBloodPressuresPerPatientPerQuarter
      .where(patient: cohort_registrations)
      .where(year: @year, quarter: @quarter)
  end

  def quarterly_controlled_bps
    quarterly_bps.where('systolic < 140 AND diastolic < 90')
  end

  def quarterly_uncontrolled_bps
    quarterly_bps.where('systolic >= 140 OR diastolic >= 90')
  end

  def monthly_registrations
    patients = Patient.where(registration_facility: @facilities)
    registration_month_start = month_start(@year, @month) - 2.months
    registration_month_end = registration_month_start.end_of_month

    patients.where('recorded_at > ? AND recorded_at <= ?',
                   registration_month_start,
                   registration_month_end)
  end

  def monthly_bps
    cohort_registrations = monthly_registrations
    LatestBloodPressuresPerPatientPerMonth
      .select("distinct on (patient_id)
       bp_id, patient_id, bp_facility_id, bp_recorded_at, deleted_at, systolic, diastolic, quarter, year")
      .order('patient_id, bp_recorded_at DESC, bp_id')
      .where(patient: cohort_registrations)
      .where('(year = ? AND month = ?) OR (year = ? AND month = ?)',
             @year.to_s, @month.to_s,
             *(previous_year_and_month(@year, @month).map(&:to_s)))
  end

  def monthly_bps_cte
    # Using the table as a CTE(nested query) is a workaround
    # for ActiveRecord's inability to compose a `COUNT` with a `DISTINCT ON`.
    LatestBloodPressuresPerPatientPerMonth
      .from(monthly_bps,
            'latest_blood_pressures_per_patient_per_months')
  end

  def monthly_controlled_bps
    monthly_bps_cte.where('systolic < 140 AND diastolic < 90')
  end

  def monthly_uncontrolled_bps
    monthly_bps_cte.where('systolic >= 140 OR diastolic >= 90')
  end
end
