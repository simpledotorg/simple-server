# frozen_string_literal: true

# Contains queries required for the My Facilities Dashboards
module MyFacilitiesQuery
  def self.inactive_facilities(facilities = Facility.all)
    facility_ids = facilities.left_outer_joins(:blood_pressures)
                             .where('blood_pressures.recorded_at IS NULL OR blood_pressures.recorded_at > ?',
                                    1.week.ago)
                             .group('facilities.id')
                             .count(:blood_pressures)
                             .select { |_, count| count < 10 }
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
