# frozen_string_literal: true

class MyFacilities::BloodPressureControlQuery
  # Wrap query method calls with the appropriate timezone in which the reports will be consumed
  # This is probably the ENV['ANALYTICS_TIME_ZONE']
  # Example: `Time.use_zone('timezone string') { bp_control_query_object.cohort_registrations }`

  include QuarterHelper
  include MonthHelper

  def initialize(selected_cohort_period: {}, facilities: Facility.all)
    @cohort_period = selected_cohort_period[:cohort_period] || :quarter
    @registration_quarter = selected_cohort_period[:registration_quarter] ||
                            previous_year_and_quarter(Time.current.year, quarter(Time.current)).second
    @registration_month = selected_cohort_period[:registration_month] ||
                          (Time.current.beginning_of_month - 1.month).month
    @registration_year = selected_cohort_period[:registration_year] ||
                         previous_year_and_quarter(Time.current.year, quarter(Time.current)).first
    @facilities = facilities
  end

  def cohort_registrations
    @cohort_period == :month ? monthly_registrations : quarterly_registrations
  end

  def cohort_controlled_bps
    @cohort_period == :month ? monthly_controlled_bps : quarterly_controlled_bps
  end

  def cohort_uncontrolled_bps
    @cohort_period == :month ? monthly_uncontrolled_bps : quarterly_uncontrolled_bps
  end

  def all_time_bps
    @all_time_bps ||= LatestBloodPressuresPerPatient
                      .where('patient_recorded_at < ?', Time.current.beginning_of_day - 2.months)
                      .where(bp_facility_id: facilities)
  end

  def all_time_controlled_bps
    @all_time_controlled_bps ||=
      all_time_bps
      .where('bp_recorded_at > ?', Time.current.beginning_of_day - 90.days)
      .under_control
  end

  private
  attr_reader :facilities

  def quarterly_registrations
    patients = Patient.where(registration_facility: facilities)

    @quarterly_registrations ||=
      patients.where('recorded_at >= ? AND recorded_at <= ?',
                     local_quarter_start(@registration_year, @registration_quarter),
                     local_quarter_end(@registration_year, @registration_quarter))
  end

  def quarterly_bps
    visited_in_quarter = next_year_and_quarter(@registration_year, @registration_quarter)
    @quarterly_bps ||=
      LatestBloodPressuresPerPatientPerQuarter
      .where(patient: quarterly_registrations)
      .where(year: visited_in_quarter.first, quarter: visited_in_quarter.second)
  end

  def quarterly_controlled_bps
    @quarterly_controlled_bps ||= quarterly_bps.under_control
  end

  def quarterly_uncontrolled_bps
    @quarterly_uncontrolled_bps ||= quarterly_bps.hypertensive
  end

  def monthly_registrations
    patients = Patient.where(registration_facility: facilities)

    @monthly_registrations ||=
      patients.where('recorded_at >= ? AND recorded_at <= ?',
                     local_month_start(@registration_year, @registration_month),
                     local_month_end(@registration_year, @registration_month))
  end

  def monthly_bps
    visited_in_months = [local_month_start(@registration_year, @registration_month) + 1.month,
                         local_month_start(@registration_year, @registration_month) + 2.months]

    @monthly_bps ||=
      LatestBloodPressuresPerPatientPerMonth
      .select("distinct on (patient_id)
       bp_id, patient_id, bp_facility_id, bp_recorded_at, deleted_at, systolic, diastolic, quarter, year")
      .order('patient_id, bp_recorded_at DESC, bp_id')
      .where(patient: monthly_registrations)
      .where('(year = ? AND month = ?) OR (year = ? AND month = ?)',
             visited_in_months.first.year.to_s, visited_in_months.first.month.to_s,
             visited_in_months.second.year.to_s, visited_in_months.second.month.to_s)
  end

  def monthly_bps_cte
    # Using the table as a CTE(nested query) is a workaround
    # for ActiveRecord's inability to compose a `COUNT` with a `DISTINCT ON`.
    @monthly_bps_cte ||=
      LatestBloodPressuresPerPatientPerMonth
      .from(monthly_bps,
            'latest_blood_pressures_per_patient_per_months')
  end

  def monthly_controlled_bps
    @monthly_controlled_bps ||= monthly_bps_cte.under_control
  end

  def monthly_uncontrolled_bps
    @monthly_uncontrolled_bps ||= monthly_bps_cte.hypertensive
  end
end
