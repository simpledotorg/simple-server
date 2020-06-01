class PatientSummary < ActiveRecord::Base
  self.primary_key = :id

  belongs_to :patient, foreign_key: :id
  belongs_to :next_appointment, class_name: 'Appointment', foreign_key: :next_appointment_id

  scope :overdue, -> { joins(:next_appointment).merge(Appointment.overdue) }
  scope :all_overdue, -> { joins(:next_appointment).merge(Appointment.all_overdue) }

  def readonly?
    true
  end
end
