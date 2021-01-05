class DiscardStaleAppointments
  def initialize(patient:)
    @patient = patient
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    stale_appointment_ids = @patient.appointments.where(status: "scheduled").pluck(:id) - [@patient.latest_scheduled_appointment.id]
    Appointment.where('id in (?)', stale_appointment_ids).discard_all
  end
end
