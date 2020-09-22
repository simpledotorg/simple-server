class Zone
  attr_reader :facility

  def initialize(facility)
    @facility = facility
  end

  def blood_pressures
    BloodPressure
      .includes(encounter: {facility: :facility_group})
      .where(facilities: {facility_group: facility_group})
      .where(facilities: {zone: zone})
  end

  def patients
    Patient
      .includes(registration_facility: :facility_group)
      .where(facilities: {facility_group: facility_group})
      .where(facilities: {zone: zone})
  end

  def medical_histories
    MedicalHistory.where(patient: patients)
  end

  def blood_sugars
    BloodSugar
      .includes(encounter: {facility: :facility_group})
      .where(facilities: {facility_group: facility_group})
      .where(facilities: {zone: zone})
  end

  def prescription_drugs
    PrescriptionDrug
      .includes(facility: :facility_group)
      .where(facilities: {facility_group: facility_group})
      .where(facilities: {zone: zone})
  end

  def appointments
    Appointment
      .includes(facility: :facility_group)
      .where(facilities: {facility_group: facility_group})
      .where(facilities: {zone: zone})
  end

  def teleconsultations
    Teleconsultation
      .includes(facility: :facility_group)
      .where(facilities: {facility_group: facility_group})
      .where(facilities: {zone: zone})
  end

  private

  def zone
    facility.zone
  end

  def facility_group
    facility.facility_group
  end
end
