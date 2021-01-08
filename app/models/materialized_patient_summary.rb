# This is the materialized version of the PatientSummary view
# It is maintained separately so that the PatientSummary view can be slowly deprecated over time in favor of this
class MaterializedPatientSummary < ActiveRecord::Base
  self.primary_key = :id

  belongs_to :patient, foreign_key: :id
  belongs_to :next_appointment, class_name: "Appointment", foreign_key: :next_appointment_id
  belongs_to :latest_bp_passport, class_name: "PatientBusinessIdentifier", foreign_key: :latest_bp_passport_id
  belongs_to :latest_blood_sugar, class_name: "BloodSugar", foreign_key: :latest_blood_sugar_id
  has_many :appointments, through: :patient
  has_many :prescription_drugs, through: :patient

  scope :overdue, -> { joins(:next_appointment).merge(Appointment.overdue) }
  scope :all_overdue, -> { joins(:next_appointment).merge(Appointment.all_overdue) }

  def self.refresh
    Scenic.database.refresh_materialized_view(table_name, concurrently: false, cascade: false)
  end

  def readonly?
    true
  end
end
