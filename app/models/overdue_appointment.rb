class OverdueAppointment < Struct.new(:patient, :latest_blood_pressure, :latest_overdue_appointment)
  def self.for_facility(facility)
    facility.patients.map { |patient| for_patient(patient) }.compact
  end

  def self.for_patient(patient)
    if patient.latest_overdue_appointment.present? && patient.latest_blood_pressure.present?
      OverdueAppointment.new(patient,
                             patient.latest_blood_pressure,
                             patient.latest_overdue_appointment)
    end
  end
end