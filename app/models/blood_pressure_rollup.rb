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

  def self.controlled_in_month(time, facilities: nil)
    range = [time.month, time.advance(months: -1).month, time.advance(months: -2).month]
    sql = <<-SQL
      SELECT count(1)
      FROM (
        SELECT DISTINCT ON (patient_id) *
        FROM #{table_name}
        WHERE period_number in (?)
        AND period_type = 0
        #{"AND assigned_facility_id in (?)" if facilities}
        ORDER BY patient_id ASC, (year, period_number) DESC
      ) AS counts
      WHERE diastolic >= 90
      and systolic >= 140
    SQL
    params = [sql, range]
    params << facilities if facilities
    query = sanitize_sql_array(params)
    connection.select_all(query).to_hash.first
  end

  def self.from_blood_pressure(blood_pressure)
    blood_pressure.create_or_update_rollup
  end
end
