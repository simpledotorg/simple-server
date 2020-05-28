class BloodPressureRollup < ApplicationRecord
  upsert_keys ["blood_pressure_id", "patient_id", "period_number", "period_type", "year"]

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

    month = blood_pressure.recorded_at.month
    quarter = quarter_for_month(month)

    month_attrs = attrs.merge(period_type: :month, period_number: month)
    quarter_attrs = attrs.merge(period_type: :quarter, period_number: quarter)
    month_rollup = BloodPressureRollup.new(month_attrs)
    month_rollup.upsert(attributes: [:diastolic, :systolic, :recorded_at])
    quarter_rollup = BloodPressureRollup.new(quarter_attrs)
    quarter_rollup.upsert(attributes: [:diastolic, :systolic, :recorded_at])
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
