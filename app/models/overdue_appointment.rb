class OverdueAppointment < Struct.new(:patient, :blood_pressure, :appointment)
  def self.for_admin(admin)
    admin.patients.map { |patient| for_patient(patient) }.compact
  end

  def self.for_patient(patient)
    if patient.latest_blood_pressure.present? && patient.latest_scheduled_appointment&.overdue?
      OverdueAppointment.new(patient,
                             patient.latest_blood_pressure,
                             patient.latest_scheduled_appointment)
    end
  end
end