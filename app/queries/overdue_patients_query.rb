class OverduePatientsQuery
  attr_reader :facilities

  MAX_SYSTOLIC = 140
  MAX_DIASTOLIC = 90

  def initialize(facilities = Facility.none, overdue_period = 90.days)
    @facilities = facilities
    @overdue_period = overdue_period
  end

  def call
    Patient.where(registration_facility: facilities).joins(:blood_pressures)
      .where('blood_pressures.device_created_at = (select max(blood_pressures.device_created_at) from blood_pressures where blood_pressures.patient_id = patients.id)')
      .where('blood_pressures.systolic > ?', MAX_SYSTOLIC)
      .where('blood_pressures.diastolic > ?', MAX_DIASTOLIC)
      .where('blood_pressures.device_created_at < ?', @overdue_period.ago)
  end
end