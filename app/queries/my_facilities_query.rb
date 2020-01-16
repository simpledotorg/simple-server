# frozen_string_literal: true
include QuarterHelper

module MyFacilitiesQuery
  INACTIVITY_THRESHOLD_PERIOD = 1.week.ago
  INACTIVITY_THRESHOLD_BPS = 10

  def self.inactive_facilities(facilities = Facility.all)
    facility_ids = facilities.left_outer_joins(:blood_pressures)
                             .where('blood_pressures.recorded_at IS NULL OR blood_pressures.recorded_at > ?',
                                    INACTIVITY_THRESHOLD_PERIOD)
                             .group('facilities.id')
                             .count(:blood_pressures)
                             .select { |_, count| count < INACTIVITY_THRESHOLD_BPS }
                             .keys

    facilities.where(id: facility_ids)
  end

  def self.latest_bps_per_patient_per_quarter(facilities = Facility.all)
    LatestBloodPressuresPerPatientPerMonth
      .select("distinct on (patient_id, year, quarter) " \
        "id, patient_id, facility_id, recorded_at, deleted_at, systolic, diastolic, quarter, year")
      .order("patient_id, year, quarter, recorded_at DESC, id")
      .where(facility_id: facilities)
  end

  def self.cohort_registrations(facilities = Facility.all)
    patients = Patient.where(registration_facility: facilities)
    cohort_start = quarter_start(2019, 3)
    cohort_end = quarter_end(2019, 3)

    patients.where('recorded_at > ? AND recorded_at <= ?', cohort_start, cohort_end)
  end

  def self.cohort_controlled_bps(facilities = Facility.all)
    cohort_registrations = cohort_registrations(facilities)
    LatestBloodPressuresPerPatientPerMonth
      .from(latest_bps_per_patient_per_quarter(facilities),
            'latest_blood_pressures_per_patient_per_months')
      .where(patient_id: cohort_registrations.map(&:id))
      .where("year = '2019' AND quarter = '4'")
      .where('systolic < 140 AND diastolic < 90')
  end

  def self.cohort_uncontrolled_bps(facilities = Facility.all)
    cohort_registrations = cohort_registrations(facilities)
    LatestBloodPressuresPerPatientPerMonth
      .from(latest_bps_per_patient_per_quarter(facilities),
            'latest_blood_pressures_per_patient_per_months')
      .where(patient_id: cohort_registrations.map(&:id))
      .where("year = '2019' AND quarter = '4'")
      .where('systolic >= 140 AND diastolic >= 90')
  end
end
