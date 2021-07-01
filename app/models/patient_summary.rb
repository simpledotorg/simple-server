class PatientSummary < ActiveRecord::Base
  self.primary_key = :id

  belongs_to :patient, foreign_key: :id
  belongs_to :next_appointment, class_name: "Appointment", foreign_key: :next_appointment_id

  scope :overdue, -> { joins(:next_appointment).merge(Appointment.overdue) }
  scope :all_overdue, -> { joins(:next_appointment).merge(Appointment.all_overdue) }
  scope :missed_appointments, -> { joins(:next_appointment).merge(Appointment.missed_appointments) }
  scope :missed_appointments_in_last_year, -> { joins(:next_appointment).merge(Appointment.missed_appointments_in_last_year) }

  def readonly?
    true
  end
end
