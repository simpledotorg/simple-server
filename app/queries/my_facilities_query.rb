# frozen_string_literal: true
include QuarterHelper

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
    quarterly_registrations(facilities)
  end

  def cohort_controlled_bps(facilities = Facility.all)
    quarterly_controlled_bps(facilities)
  end

  def cohort_uncontrolled_bps(facilities = Facility.all)
    quarterly_uncontrolled_bps(facilities)
  end

  private

  def latest_bps_per_patient_per_quarter(facilities = Facility.all)
    LatestBloodPressuresPerPatientPerMonth
        .select("distinct on (patient_id, year, quarter)
         id, patient_id, facility_id, recorded_at, deleted_at, systolic, diastolic, quarter, year")
        .order("patient_id, year, quarter, recorded_at DESC, id")
        .where(facility_id: facilities)
  end

  def latest_bps_per_patient_per_quarter_cte(facilities = Facility.all)
    # Using the quarterly table as a CTE(nested query) is a workaround
    # for ActiveRecord's inability to compose a `COUNT` with a `DISTINCT ON`.
    LatestBloodPressuresPerPatientPerMonth
        .from(latest_bps_per_patient_per_quarter(facilities),
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
end
