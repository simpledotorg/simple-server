class NoBPMeasureService
  CACHE_VERSION = 5

  def initialize(region, periods:)
    @region = region
    @periods = periods
    @facilities = region.facilities.to_a
  end

  attr_reader :facilities
  attr_reader :periods
  attr_reader :region

  def call
    periods.each_with_object(Hash.new(0)) do |period, result|
      result[period] = visited_without_bp_taken_for(period)
    end
  end

  def visited_without_bp_taken_for(period)
    if facilities.empty?
      return 0
    end
    attributes = {
      hypertension: "yes",
      facilities: facilities.map(&:id),
      start_date: period.blood_pressure_control_range.begin,
      end_date: period.blood_pressure_control_range.end,
      registration_date: period.blood_pressure_control_range.begin
    }
    sql = GitHub::SQL.new(<<-SQL, attributes)
      SELECT COUNT(DISTINCT "patients"."id")
      FROM "patients"
        INNER JOIN "medical_histories" ON "medical_histories"."patient_id" = "patients"."id"
        LEFT OUTER JOIN appointments ON appointments.patient_id = patients.id
          AND appointments.device_created_at > :start_date
          AND appointments.device_created_at <= :end_date
        LEFT OUTER JOIN prescription_drugs ON prescription_drugs.patient_id = patients.id
          AND prescription_drugs.device_created_at > :start_date
          AND prescription_drugs.device_created_at <= :end_date
        LEFT OUTER JOIN blood_sugars ON blood_sugars.patient_id = patients.id
          AND blood_sugars.recorded_at > :start_date
          AND blood_sugars.recorded_at <= :end_date
      WHERE "patients"."deleted_at" IS NULL
        AND "medical_histories"."deleted_at" IS NULL
        AND "medical_histories"."hypertension" = :hypertension
        AND "patients"."registration_facility_id" in :facilities
        AND patients.recorded_at <= :registration_date
        AND (appointments.id IS NOT NULL
            OR prescription_drugs.id IS NOT NULL
            OR blood_sugars.id IS NOT NULL)
        AND (NOT EXISTS (
          SELECT
            1
          FROM
            blood_pressures bps
          WHERE
            patients.id = bps.patient_id
            AND bps.recorded_at > :start_date
            AND bps.recorded_at <= :end_date)
        ) -- #{self.class.name} period #{period} facilities #{facilities.map(&:id)}
    SQL
    sql.value
  end

  def cache_key
    "#{self.class}/#{region.model_name}/#{region.id}/#{periods_cache_key}"
  end

  def cache_version
    "#{region.updated_at.utc.to_s(:usec)}/#{CACHE_VERSION}"
  end

  def periods_cache_key
    "#{periods.begin.value}/#{periods.end.value}"
  end

  def force_cache?
    RequestStore.store[:force_cache]
  end
end
