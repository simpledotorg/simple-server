# frozen_string_literal: true

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

  def self.latest_blood_pressures_per_patient_per_quarter
    LatestBloodPressuresPerPatientPerMonth
      .select("distinct on (patient_id, year, quarter) " \
        "id, patient_id, facility_id, recorded_at, systolic, diastolic, quarter, year")
      .order("patient_id, year, quarter, recorded_at DESC, id")
  end
end
