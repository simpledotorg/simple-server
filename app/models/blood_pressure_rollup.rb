class BloodPressureRollup < ApplicationRecord
  upsert_keys ["patient_id", "period_number", "period_type", "year"]

  belongs_to :blood_pressure
  belongs_to :patient
  belongs_to :assigned_facility, class_name: "Facility"
  belongs_to :blood_pressure_facility, class_name: "Facility"

  enum period_type: {month: 0, quarter: 1}

  validates :diastolic, presence: true
  validates :systolic, presence: true
  validates :period_number, presence: true, numericality: {only_integer: true}
  validates :period_type, presence: true
  validates :year, presence: true, numericality: {greater_than_or_equal_to: 2000, only_integer: true}

  def self.controlled_in_month(time)
    range = [time.month, time.advance(months: -1).month, time.advance(months: -2).month]
    sql = <<-SQL
      SELECT count(1)
      FROM (
        SELECT DISTINCT ON (patient_id) *
        FROM #{table_name}
        WHERE period_number in (?)
        AND period_type = 0
        ORDER BY patient_id ASC, (year, period_number) DESC
      ) AS counts
      WHERE diastolic >= 90
      and systolic >= 140
    SQL
    query = sanitize_sql_array([sql, range])
    connection.select_all(query).to_hash
  end

  def self.from_blood_pressure(blood_pressure)
    attrs = {
      assigned_facility_id: blood_pressure.patient.registration_facility_id,
      blood_pressure_facility_id: blood_pressure.facility_id,
      blood_pressure_id: blood_pressure.id,
      diastolic: blood_pressure.diastolic,
      patient_id: blood_pressure.patient_id,
      recorded_at: blood_pressure.recorded_at,
      systolic: blood_pressure.systolic,
      year: blood_pressure.recorded_at.year
    }

    previous_rollup_recorded_at = if blood_pressure.merge_status == :updated
      BloodPressureRollup.where(blood_pressure: blood_pressure).pluck(:recorded_at)
    end

    month = blood_pressure.recorded_at.month
    quarter = quarter_for_month(month)

    month_attrs = attrs.merge(period_type: :month, period_number: month)
    quarter_attrs = attrs.merge(period_type: :quarter, period_number: quarter)
    month_rollup = BloodPressureRollup.new(month_attrs)
    result = month_rollup.upsert(attributes: [:blood_pressure_id, :diastolic, :period_number, :systolic, :recorded_at],
                        arel_condition: BloodPressureRollup.arel_table[:recorded_at].lt(blood_pressure.recorded_at))
    logger.info "result for month upsert #{result.attributes}"
    quarter_rollup = BloodPressureRollup.new(quarter_attrs)
    quarter_rollup.upsert(attributes: [:blood_pressure_id, :diastolic, :systolic, :recorded_at],
                          arel_condition: BloodPressureRollup.arel_table[:recorded_at].lt(blood_pressure.recorded_at))

    recorded_at = previous_rollup_recorded_at&.first
    if recorded_at
      logger.info "in previous rollups with #{recorded_at}"
      most_recent_bp_for_period = BloodPressure.recent_in_month(recorded_at, patients: blood_pressure.patient_id).first
      from_blood_pressure(most_recent_bp_for_period)
    end
  end

  def self.quarter_for_month(month)
    case month
    when 1, 2, 3
      1
    when 4, 5, 6
      2
    when 7, 8, 9
      3
    when 10, 11, 12
      4
    else
      raise ArgumentError
    end
  end
end
