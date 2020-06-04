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
    blood_pressure.to_rollup
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
