class NoBPMeasureService
  CACHE_VERSION = 3
  VALID_GROUPS = [:missed_visits, :lost_to_followup]

  def initialize(region, periods:, group: :missed_visits)
    unless VALID_GROUPS.include?(group)
      raise ArgumentError, "invalid group #{group}, must be one of #{VALID_GROUPS}"
    end
    @region = region
    @periods = periods
    @facilities = region.facilities.to_a
    @group = group
  end

  attr_reader :facilities
  attr_reader :periods
  attr_reader :region
  attr_reader :group

  def call
    Rails.cache.fetch(cache_key, version: cache_version, expires_in: 7.days, force: force_cache?) do
      periods.each_with_object({}) do |period, result|
        result[period] = missed_visits_for(period)
      end
    end
  end

  def missed_visits_for(period)
    if group == :missed_visits
      visit_start_range = period.advance(years: -1).start_date
      visit_end_range = period.advance(months: -3).start_date
    else
      visit_start_range = "-infinity"
      visit_end_range = period.advance(years: -1).start_date
    end
    bind_attributes = {
      hypertension: "yes",
      facilities: facilities.map(&:id),
      bp_start_range: period.advance(months: -3).start_date,
      bp_end_range: period.end_date,
      registration_date: period.end_date,
      visit_start_range: visit_start_range,
      visit_end_range: visit_end_range,
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
      WHERE "patients"."deleted_at" IS NULL
        AND "medical_histories"."deleted_at" IS NULL
        AND "medical_histories"."hypertension" = :hypertension
        AND "patients"."registration_facility_id" in :facilities
        AND patients.recorded_at >= :visit_start_range
        AND patients.recorded_at < :visit_end_range
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

  def cache_key
    "#{self.class}/#{group}/#{region.model_name}/#{region.id}/#{periods_cache_key}"
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
