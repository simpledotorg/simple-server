# This is the materialized version of the PatientSummary view
# It is maintained separately so that the PatientSummary view can be slowly deprecated over time in favor of this
class MaterializedPatientSummary < ActiveRecord::Base
  self.primary_key = :id
  extend Reports::Refreshable

  belongs_to :patient, foreign_key: :id
  belongs_to :next_scheduled_appointment, class_name: "Appointment", foreign_key: :next_scheduled_appointment_id
  belongs_to :latest_bp_passport, class_name: "PatientBusinessIdentifier", foreign_key: :latest_bp_passport_id
  belongs_to :latest_blood_sugar, class_name: "BloodSugar", foreign_key: :latest_blood_sugar_id

  has_many :appointments, foreign_key: :patient_id
  has_many :prescription_drugs, foreign_key: :patient_id
  has_many :current_prescription_drugs, -> { where(is_deleted: false).order(created_at: :desc) }, class_name: "PrescriptionDrug", foreign_key: :patient_id
  has_many :latest_blood_pressures, -> { order(recorded_at: :desc) }, class_name: "BloodPressure", foreign_key: :patient_id

  scope :overdue, -> { joins(:next_scheduled_appointment).merge(Appointment.overdue) }
  scope :all_overdue, -> { joins(:next_scheduled_appointment).merge(Appointment.all_overdue) }

  def readonly?
    true
  end

  def prescribed_drugs(date: Date.current)
    prescription_drugs.prescribed_as_of(date)
  end

  def ltfu?
    recorded_at < Patient::LTFU_TIME.ago &&
      (latest_blood_pressure_recorded_at.nil? || latest_blood_pressure_recorded_at < Patient::LTFU_TIME.ago) &&
      (latest_blood_sugar_recorded_at.nil? || latest_blood_sugar_recorded_at < Patient::LTFU_TIME.ago) &&
      (next_scheduled_appointment&.device_created_at.nil? || next_scheduled_appointment.device_created_at < Patient::LTFU_TIME.ago) &&
      (current_prescription_drugs&.first&.device_created_at.nil? || current_prescription_drugs.first.device_created_at < Patient::LTFU_TIME.ago)
  end
end
