class NoBPMeasureService
  def initialize(region, periods:, type: :missed_visits)
    @region = region
    @periods = periods
    @facilities = region.facilities.to_a
    @type = type
  end

  attr_reader :facilities
  attr_reader :periods
  attr_reader :region
  attr_reader :type

  def call
    periods.each_with_object({}) do |period, result|
      result[period] = missed_visits_for(period)
    end
  end

  def missed_visits_for(period)
    if type == :missed_visits
      visit_start_range = period.advance(years: -1).start_date
      visit_end_range = period.advance(months: -3).start_date
    else
      visit_start_range = "-infinity"
      visit_end_range = period.advance(years: -1).start_date
    end
    bind_attributes = {
      hypertension: "yes",
      facilities: facilities.map(&:id),
      visit_start_range: visit_start_range,
      visit_end_range: visit_end_range,
      bp_start_range: period.advance(months: -3).start_date,
      bp_end_range: period.end_date
    }
    sql = GitHub::SQL.new(<<-SQL, bind_attributes)
      SELECT COUNT(DISTINCT "patients"."id")
      FROM "patients"
        INNER JOIN "medical_histories" ON "medical_histories"."deleted_at" IS NULL
          AND "medical_histories"."patient_id" = "patients"."id"
        LEFT OUTER JOIN appointments ON appointments.patient_id = patients.id
          AND appointments.device_created_at >= :visit_start_range
          AND appointments.device_created_at < :visit_end_range
        LEFT OUTER JOIN prescription_drugs ON prescription_drugs.patient_id = patients.id
          AND prescription_drugs.device_created_at >= :visit_start_range
          AND prescription_drugs.device_created_at < :visit_end_range
        LEFT OUTER JOIN blood_sugars ON blood_sugars.patient_id = patients.id
          AND blood_sugars.recorded_at >= :visit_start_range
          AND blood_sugars.recorded_at < :visit_end_range
      WHERE
            "patients"."deleted_at" IS NULL
        AND "medical_histories"."deleted_at" IS NULL
        AND "medical_histories"."hypertension" = :hypertension
        AND "patients"."registration_facility_id" in :facilities
        AND (appointments.id IS NOT NULL OR prescription_drugs.id IS NOT NULL OR blood_sugars.id IS NOT NULL)
        AND (NOT EXISTS (
          SELECT
            1
          FROM
            blood_pressures bps
          WHERE
            patients.id = bps.patient_id
            AND bps.recorded_at >= :bp_start_range
            AND bps.recorded_at <= :bp_end_range)
        ) -- For Period #{period}
    SQL
    sql.value
  end
end