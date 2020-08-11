class NoBPMeasureService
  CACHE_VERSION = 5
  VALID_GROUPS = [:missed_visits, :lost_to_followup, :no_recent_bp]

  def initialize(region, periods:, group: :missed_visits)
    unless VALID_GROUPS.include?(group)
      raise ArgumentError, "invalid group #{group}, must be one of #{VALID_GROUPS}"
    end
    @region = region
    @periods = periods
    @facilities = region.facilities.to_a
    @group = group
  end

  def visit_range_for(period)
    if group == :lost_to_followup
      start_date = Time.at(0).utc.to_date
      end_date = period.advance(years: -1).end_date
    elsif group == :missed_visits
      start_date = period.advance(years: -1).end_date
      end_date = period.advance(months: -3).end_date
    else # last 90 days
      start_date = period.blood_pressure_control_range.begin
      end_date = period.blood_pressure_control_range.end
    end
    (start_date..end_date)
  end

  attr_reader :facilities
  attr_reader :periods
  attr_reader :visit_end_date
  attr_reader :region
  attr_reader :group

  def call
    # Rails.cache.fetch(cache_key, version: cache_version, expires_in: 7.days, force: force_cache?) do
      periods.each_with_object({}) do |period, result|
        result[period] = missed_visits_for(period)
      # end
    end
  end

  def missed_visits_for(period)
    range = visit_range_for(period)
    visit_start_date = range.begin
    visit_end_date = range.end

    bind_attributes = {
      hypertension: "yes",
      facilities: facilities.map(&:id),
      bp_start_date: period.blood_pressure_control_range.begin,
      bp_end_date: period.blood_pressure_control_range.end,
      registration_date: period.end_date,
      visit_start_date: visit_start_date,
      visit_end_date: visit_end_date,
    }
    sql = GitHub::SQL.new(<<-SQL, bind_attributes)
      SELECT COUNT(DISTINCT "patients"."id")
      FROM "patients"
        INNER JOIN "medical_histories" ON "medical_histories"."patient_id" = "patients"."id"
        LEFT OUTER JOIN appointments ON appointments.patient_id = patients.id
          AND appointments.device_created_at > :visit_start_date
          AND appointments.device_created_at <= :visit_end_date
        LEFT OUTER JOIN prescription_drugs ON prescription_drugs.patient_id = patients.id
          AND prescription_drugs.device_created_at > :visit_start_date
          AND prescription_drugs.device_created_at <= :visit_end_date
        LEFT OUTER JOIN blood_sugars ON blood_sugars.patient_id = patients.id
          AND blood_sugars.recorded_at > :visit_start_date
          AND blood_sugars.recorded_at <= :visit_end_date
      WHERE "patients"."deleted_at" IS NULL
        AND "medical_histories"."deleted_at" IS NULL
        AND "medical_histories"."hypertension" = :hypertension
        AND "patients"."registration_facility_id" in :facilities
        AND patients.recorded_at <= :registration_date
        AND (appointments.id IS NOT NULL
            OR prescription_drugs.id IS NOT NULL
            OR blood_sugars.id IS NOT NULL
            OR (
                  patients.recorded_at > :visit_start_date
              AND patients.recorded_at <= :visit_end_date
            )
        )
        AND (NOT EXISTS (
          SELECT
            1
          FROM
            blood_pressures bps
          WHERE
            patients.id = bps.patient_id
            AND bps.recorded_at > :bp_start_date
            AND bps.recorded_at <= :bp_end_date)
        ) -- #{self.class.name} group #{group} period #{period}
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
