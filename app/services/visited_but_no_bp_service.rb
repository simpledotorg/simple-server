class VisitedButNoBPService
  def initialize(region, periods:)
    @region = region
    @periods = periods
    @facilities = region.facilities.to_a
  end

  attr_reader :facilities
  attr_reader :periods
  attr_reader :region

  def call
    periods.each_with_object({}) do |period, result|
      result[period] = patients_visited_with_no_bp_taken(period).count
    end
  end

  def missed_visits
    periods.each_with_object({}) do |period, result|
      result[period] = missed_visits_for(period)
    end
  end

  def patients_visited_with_no_bp_taken(period)
    Patient
      .distinct
      .with_hypertension
      .where(registration_facility: facilities)
      .joins(left_outer_join("appointments", period))
      .joins(left_outer_join("prescription_drugs", period))
      .joins(left_outer_join("blood_sugars", period, field: "recorded_at"))
      .where("appointments.id IS NOT NULL OR prescription_drugs.id IS NOT NULL OR blood_sugars.id IS NOT NULL")
      .where(no_blood_pressures_recorded(period))
  end

  def between_clause(table, field, period)
    begin_date = period.blood_pressure_control_range.begin
    end_date = period.blood_pressure_control_range.end
    sql = ["#{table}.#{field} > ? AND #{table}.#{field} <= ?", begin_date, end_date]
    ActiveRecord::Base.sanitize_sql_for_conditions(sql)
  end

  def no_blood_pressures_recorded(period)
    <<-SQL
      NOT EXISTS (
        SELECT 1
        FROM blood_pressures bps
        WHERE patients.id = bps.patient_id
          AND #{between_clause("bps", "recorded_at", period)}
      )
    SQL
  end

  private

  def left_outer_join(table, period, field: "device_created_at")
    clause = between_clause(table, field, period)
    "LEFT OUTER JOIN #{table} ON #{table}.patient_id = patients.id AND #{clause}"
  end
end
