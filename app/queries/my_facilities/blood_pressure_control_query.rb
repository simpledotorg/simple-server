# frozen_string_literal: true

class MyFacilities::BloodPressureControlQuery
  # Wrap query method calls with the appropriate timezone in which the reports will be consumed
  # This is probably the `Rails.application.config.country[:time_zone]`
  # Example: `Time.use_zone('timezone string') { bp_control_query_object.cohort_registrations }`

  include QuarterHelper
  include MonthHelper

  REGISTRATION_BUFFER = 3.months

  def initialize(facilities: Facility.all, cohort_period: {})
    # cohort_period is map that contains
    # - :cohort_period (:quarter/:month),
    # - :registration_quarter/:registration_month
    # - :registration_year
    @cohort_period = cohort_period[:cohort_period]
    @registration_quarter = cohort_period[:registration_quarter]
    @registration_month = cohort_period[:registration_month]
    @registration_year = cohort_period[:registration_year]
    @facilities = Facility.where(id: facilities)
  end

  def cohort_patients_per_facility
    cohort_patients.group(:assigned_facility_id).count
  end

  def cohort_controlled_bps_per_facility
    cohort_controlled_bps.group(:assigned_facility_id).count
  end

  def cohort_uncontrolled_bps_per_facility
    cohort_uncontrolled_bps.group(:assigned_facility_id).count
  end

  def cohort_bps_per_facility
    @cohort_bps_per_facility ||=
      cohort_bps.group(:assigned_facility_id).count
  end

  def cohort_patients
    @cohort_period == :month ? monthly_patients : quarterly_patients
  end

  def cohort_controlled_bps
    @cohort_period == :month ? monthly_controlled_bps : quarterly_controlled_bps
  end

  def cohort_uncontrolled_bps
    @cohort_period == :month ? monthly_uncontrolled_bps : quarterly_uncontrolled_bps
  end

  def cohort_bps
    @cohort_period == :month ? monthly_bps_cte : quarterly_bps
  end

  def cohort_missed_visits_count
    cohort_patients.count - cohort_bps.count
  end

  def cohort_missed_visits_count_by_facility
    patients = cohort_patients_per_facility
    bps = cohort_bps_per_facility

    @facilities.map { |f|
      [f.id, (patients[f.id].to_i - bps[f.id].to_i)]
    }.to_h
  end

  def overall_patients_per_facility
    overall_patients.group(:assigned_facility_id).count
  end

  def overall_controlled_bps_per_facility
    overall_controlled_bps.group(:assigned_facility_id).count
  end

  def overall_patients
    @overall_patients ||=
      Patient
        .with_hypertension
        .where(assigned_facility: facilities)
        .where("recorded_at < ?", Time.current.beginning_of_day - REGISTRATION_BUFFER)
  end

  def overall_controlled_bps
    @overall_controlled_bps ||=
      LatestBloodPressuresPerPatient
        .where(patient: overall_patients)
        .where("bp_recorded_at > ?", Time.current.beginning_of_day - 90.days)
        .under_control
  end

  private

  attr_reader :facilities

  def quarterly_patients
    @quarterly_patients ||=
      Patient
        .with_hypertension
        .where(assigned_facility: facilities)
        .where("recorded_at >= ? AND recorded_at <= ?",
          local_quarter_start(@registration_year, @registration_quarter),
          local_quarter_end(@registration_year, @registration_quarter))
  end

  def quarterly_bps
    visited_in_quarter = next_year_and_quarter(@registration_year, @registration_quarter)
    @quarterly_bps ||=
      LatestBloodPressuresPerPatientPerQuarter
        .where(patient: quarterly_patients)
        .where(year: visited_in_quarter.first, quarter: visited_in_quarter.second)
  end

  def quarterly_controlled_bps
    @quarterly_controlled_bps ||= quarterly_bps.under_control
  end

  def quarterly_uncontrolled_bps
    @quarterly_uncontrolled_bps ||= quarterly_bps.hypertensive
  end

  def monthly_patients
    @monthly_patients ||=
      Patient
        .with_hypertension
        .where(assigned_facility: facilities)
        .where("recorded_at >= ? AND recorded_at <= ?",
          local_month_start(@registration_year, @registration_month),
          local_month_end(@registration_year, @registration_month))
  end

  def monthly_bps
    visited_in_months = [local_month_start(@registration_year, @registration_month) + 1.month,
      local_month_start(@registration_year, @registration_month) + 2.months]

    @monthly_bps ||=
      LatestBloodPressuresPerPatientPerMonth
        .select("distinct on (patient_id) *")
        .order("patient_id, bp_recorded_at DESC, bp_id")
        .where(patient: monthly_patients)
        .where("(year = ? AND month = ?) OR (year = ? AND month = ?)",
          visited_in_months.first.year.to_s, visited_in_months.first.month.to_s,
          visited_in_months.second.year.to_s, visited_in_months.second.month.to_s)
  end

  def monthly_bps_cte
    # Using the table as a CTE(nested query) is a workaround
    # for ActiveRecord's inability to compose a `COUNT` with a `DISTINCT ON`.
    @monthly_bps_cte ||=
      LatestBloodPressuresPerPatientPerMonth
        .from(monthly_bps,
          "latest_blood_pressures_per_patient_per_months")
  end

  def monthly_controlled_bps
    @monthly_controlled_bps ||= monthly_bps_cte.under_control
  end

  def monthly_uncontrolled_bps
    @monthly_uncontrolled_bps ||= monthly_bps_cte.hypertensive
  end
end
