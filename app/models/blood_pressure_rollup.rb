class BloodPressureRollup < ApplicationRecord
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
end
