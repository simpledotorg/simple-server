class HypertensivePatientsQuery
  attr_reader :relation

  MAX_SYSTOLIC = 140
  MAX_DIASTOLIC = 90

  def initialize(relation = Patient.none)
    @relation = relation
  end

  def call
    relation.joins(:blood_pressures)
      .where('blood_pressures.device_created_at = (select max(blood_pressures.device_created_at) from blood_pressures where blood_pressures.patient_id = patients.id)')
      .where('blood_pressures.systolic > ?', MAX_SYSTOLIC)
      .where('blood_pressures.diastolic > ?', MAX_DIASTOLIC)
  end
end