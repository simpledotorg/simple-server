# frozen_string_literal: true
include QuarterHelper
include MonthHelper

class MyFacilitiesQuery
  INACTIVITY_THRESHOLD_PERIOD = 1.week.ago
  INACTIVITY_THRESHOLD_BPS = 10

  def initialize(period: :quarter, quarter: quarter(Time.current), month: Time.current.month, year: Time.current.year)
    @period = period
    @month = month
    @quarter = quarter
    @year = year
  end

  def inactive_facilities(facilities = Facility.all)
    facility_ids = facilities.left_outer_joins(:blood_pressures)
                             .where('blood_pressures.recorded_at IS NULL OR blood_pressures.recorded_at > ?',
                                    INACTIVITY_THRESHOLD_PERIOD)
                             .group('facilities.id')
                             .count(:blood_pressures)
                             .select { |_, count| count < INACTIVITY_THRESHOLD_BPS }
                             .keys

    facilities.where(id: facility_ids)
  end

  def cohort_registrations(facilities = Facility.all)
    @period == :month ? monthly_registrations(facilities) : quarterly_registrations(facilities)
  end

  def cohort_controlled_bps(facilities = Facility.all)
    @period == :month ? monthly_controlled_bps(facilities) : quarterly_controlled_bps(facilities)
  end

  def cohort_uncontrolled_bps(facilities = Facility.all)
    @period == :month ? monthly_uncontrolled_bps(facilities) : quarterly_uncontrolled_bps(facilities)
  end

  def cohort_all_time_patients(facilities = Facility.all)
    @period == :month ? monthly_all_time_patients(facilities) : quarterly_all_time_patients(facilities)
  end

  def cohort_all_time_controlled_bps(facilities = Facility.all)
    @period == :month ? monthly_all_time_controlled_bps(facilities) : quarterly_all_time_controlled_bps(facilities)
  end

  private

  def latest_bps_per_patient_per_quarter(facilities = Facility.all)
    LatestBloodPressuresPerPatientPerMonth
      .select("distinct on (patient_id, year, quarter)
         bp_id, patient_id, bp_facility_id, bp_recorded_at, deleted_at, systolic, diastolic, quarter, year")
      .order("patient_id, year, quarter, bp_recorded_at DESC, bp_id")
      .where(bp_facility_id: facilities)
  end

  def latest_bps_per_patient(facilities = Facility.all)
    LatestBloodPressuresPerPatientPerMonth
      .select("distinct on (patient_id)
         bp_id, patient_id, bp_facility_id, bp_recorded_at, patient_recorded_at, deleted_at, systolic, diastolic, quarter, year")
      .order("patient_id, bp_recorded_at DESC, bp_id")
      .where(bp_facility_id: facilities)
  end

  def latest_bps_per_patient_per_quarter_cte(facilities = Facility.all)
    # Using the quarterly table as a CTE(nested query) is a workaround
    # for ActiveRecord's inability to compose a `COUNT` with a `DISTINCT ON`.
    LatestBloodPressuresPerPatientPerMonth
      .from(latest_bps_per_patient_per_quarter(facilities),
            'latest_blood_pressures_per_patient_per_months')
  end

  def latest_bps_per_patient_cte(facilities = Facility.all)
    # Using the quarterly table as a CTE(nested query) is a workaround
    # for ActiveRecord's inability to compose a `COUNT` with a `DISTINCT ON`.
    LatestBloodPressuresPerPatientPerMonth
      .from(latest_bps_per_patient(facilities),
            'latest_blood_pressures_per_patient_per_months')
  end

  def quarterly_registrations(facilities)
    patients = Patient.where(registration_facility: facilities)
    previous_cohort = previous_year_and_quarter(@year, @quarter)

    patients.where('recorded_at > ? AND recorded_at <= ?',
                   quarter_start(*previous_cohort),
                   quarter_end(*previous_cohort))
  end

  def quarterly_bps(facilities)
    cohort_registrations = quarterly_registrations(facilities)
    latest_bps_per_patient_per_quarter_cte
      .where(patient_id: cohort_registrations.map(&:id))
      .where(year: @year, quarter: @quarter)
  end

  def quarterly_controlled_bps(facilities)
    quarterly_bps(facilities).where('systolic < 140 AND diastolic < 90')
  end

  def quarterly_uncontrolled_bps(facilities)
    quarterly_bps(facilities).where('systolic >= 140 OR diastolic >= 90')
  end

  def quarterly_all_time_patients(facilities = Facility.all)
    registration_cutoff = quarter_start(@year, @quarter) - 2.months
    latest_bps_per_patient_cte
      .where('patient_recorded_at <= ?', registration_cutoff)
      .where(bp_facility_id: facilities)
  end

  def quarterly_all_time_controlled_bps(facilities)
    registration_cutoff = quarter_start(@year, @quarter) - 2.months
    bp_cutoff = quarter_start(@year, @quarter).end_of_quarter
    quarterly_all_time_patients
      .where('bp_recorded_at > ? AND bp_recorded_at < ?', registration_cutoff, bp_cutoff)
      .where('systolic < 140 AND diastolic < 90')
  end

  def monthly_registrations(facilities)
    patients = Patient.where(registration_facility: facilities)
    registration_month_start = month_start(@year, @month) - 2.months
    registration_month_end = registration_month_start.end_of_month

    patients.where('recorded_at > ? AND recorded_at <= ?',
                   registration_month_start,
                   registration_month_end)
  end

  def monthly_bps(facilities)
    cohort_registrations = monthly_registrations(facilities)
    LatestBloodPressuresPerPatientPerMonth
      .where(patient_id: cohort_registrations.map(&:id))
      .where('(year = ? AND month = ?) OR (year = ? AND month = ?)',
             @year.to_s, @month.to_s,
             *(previous_year_and_month(@year, @month).map(&:to_s)))
  end

  def monthly_controlled_bps(facilities)
    monthly_bps(facilities).where('systolic < 140 AND diastolic < 90')
  end

  def monthly_uncontrolled_bps(facilities)
    monthly_bps(facilities).where('systolic >= 140 OR diastolic >= 90')
  end

  def monthly_all_time_patients(facilities = Facility.all)
    registration_cutoff = month_start(@year, @month) - 2.months
    latest_bps_per_patient_cte
      .where('patient_recorded_at < ?', registration_cutoff)
      .where(bp_facility_id: facilities)
  end

  def monthly_all_time_controlled_bps(facilities)
    registration_cutoff = month_start(@year, @month) - 2.months
    bp_cutoff = month_start(@year, @month).end_of_month
    monthly_all_time_patients
      .where('bp_recorded_at > ? AND bp_recorded_at < ?', registration_cutoff, bp_cutoff)
      .where('systolic < 140 AND diastolic < 90')
  end
end
