class NoBPMeasureQuery
  delegate :sanitize_sql, to: ActiveRecord::Base

  def call(region, period, with_exclusions: false)
    facility_ids = region.facilities.map(&:id)
    return 0 if facility_ids.blank?
    start_date = period.blood_pressure_control_range.begin
    end_date = period.blood_pressure_control_range.end
    registration_date = period.blood_pressure_control_range.begin

    Patient
      .for_reports(with_exclusions: with_exclusions, exclude_ltfu_as_of: period.start_date)
      .joins(sanitize_sql(["LEFT OUTER JOIN appointments ON appointments.patient_id = patients.id
          AND appointments.device_created_at > ?
          AND appointments.device_created_at <= ?", start_date, end_date]))
      .joins(sanitize_sql(["LEFT OUTER JOIN prescription_drugs ON prescription_drugs.patient_id = patients.id
          AND prescription_drugs.device_created_at > ?
          AND prescription_drugs.device_created_at <= ?", start_date, end_date]))
      .joins(sanitize_sql(["LEFT OUTER JOIN blood_sugars ON blood_sugars.patient_id = patients.id
          AND blood_sugars.recorded_at > ?
          AND blood_sugars.recorded_at <= ?", start_date, end_date]))
      .where(assigned_facility_id: facility_ids)
      .where("patients.recorded_at <= ?", registration_date)
      .where("appointments.id IS NOT NULL
                OR prescription_drugs.id IS NOT NULL
                OR blood_sugars.id IS NOT NULL")
      .where("NOT EXISTS
                 (SELECT 1
                  FROM blood_pressures bps
                  WHERE patients.id = bps.patient_id
                  AND bps.recorded_at > ?
                  AND bps.recorded_at <= ?)", start_date, end_date)
      .distinct("patients.id")
      .count
  end
end
