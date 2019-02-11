class OverduePatientsQuery
  attr_reader :facilities

  MAX_SYSTOLIC = 140
  MAX_DIASTOLIC = 90

  def initialize(facilities = Facility.none, overdue_period = 90.days)
    @facilities = facilities
    @overdue_period = overdue_period
  end

  def call
    HypertensivePatientsQuery.new(Patient.where(registration_facility: facilities)).call
      .where('blood_pressures.device_created_at < ?', @overdue_period.ago)
  end
end