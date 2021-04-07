class NoBPMeasureQuery
  delegate :logger, to: Rails
  delegate :sanitize_sql, to: ActiveRecord::Base

  def call(region, period, with_ltfu: false)
    logger.info { "#{self.class} called for region=#{region.slug} period=#{period} with_exclusions=#{with_exclusions}" }

    facility_ids = region.facilities.map(&:id)
    return 0 if facility_ids.blank?
    start_time = period.blood_pressure_control_range.begin
    end_time = period.blood_pressure_control_range.end
    registration_date = period.blood_pressure_control_range.begin
    exclude_ltfu_as_of = with_ltfu ? nil : period.end_time

    Patient
      .for_reports(exclude_ltfu_as_of: exclude_ltfu_as_of)
      .joins(sanitize_sql(["LEFT OUTER JOIN appointments ON appointments.patient_id = patients.id
          AND appointments.device_created_at >= ?
          AND appointments.device_created_at <= ?", start_time, end_time]))
      .joins(sanitize_sql(["LEFT OUTER JOIN prescription_drugs ON prescription_drugs.patient_id = patients.id
          AND prescription_drugs.device_created_at >= ?
          AND prescription_drugs.device_created_at <= ?", start_time, end_time]))
      .joins(sanitize_sql(["LEFT OUTER JOIN blood_sugars ON blood_sugars.patient_id = patients.id
          AND blood_sugars.recorded_at >= ?
          AND blood_sugars.recorded_at <= ?", start_time, end_time]))
      .where(assigned_facility_id: facility_ids)
      .where("patients.recorded_at <= ?", registration_date)
      .where("appointments.id IS NOT NULL
                OR prescription_drugs.id IS NOT NULL
                OR blood_sugars.id IS NOT NULL")
      .where("NOT EXISTS
                 (SELECT 1
                  FROM blood_pressures bps
                  WHERE patients.id = bps.patient_id
                  AND bps.recorded_at >= ?
                  AND bps.recorded_at <= ?)", start_time, end_time)
      .distinct("patients.id")
      .count
  end
end
