class PatientDetail < Struct.new(:patient, :latest_blood_pressure, :latest_scheduled_appointment)
  def self.for_facility(facility)
    facility.patients.map { |patient| for_patient(patient) }
  end

  def self.for_patient(patient)
    PatientDetail.new(patient,
                      patient.latest_blood_pressure,
                      patient.latest_scheduled_appointment)
  end
end