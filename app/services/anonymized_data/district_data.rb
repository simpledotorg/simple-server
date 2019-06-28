class AnonymizedData::DistrictData
  attr_reader :facilities

  def initialize(district)
    @facilities = district.facilities
  end

  def raw_data
    {
      AnonymizedData::Constants::PATIENTS_FILE =>
        facilities.map { |f| AnonymizedData::FacilityData.new(f).patient_data }.flatten,
      AnonymizedData::Constants::BPS_FILE =>
        facilities.map { |f| AnonymizedData::FacilityData.new(f).bp_data }.flatten,
      AnonymizedData::Constants::MEDICINES_FILE =>
        facilities.map { |f| AnonymizedData::FacilityData.new(f).prescription_data }.flatten,
      AnonymizedData::Constants::APPOINTMENTS_FILE =>
        appointments,
      AnonymizedData::Constants::SMS_REMINDERS_FILE =>
        communication_data(appointments),
      AnonymizedData::Constants::PHONE_CALLS_FILE =>
        phone_call_data(users_phone_numbers),
    }
  end

  def communication_data(appointments)
    appointments.flat_map(&:communications).select { |comm| comm.device_created_at >= AnonymizedData::Constants::ANONYMIZATION_START_DATE }
  end

  def phone_call_data(users_phone_numbers)
    CallLog.all.select { |call| users_phone_numbers.include?(call.caller_phone_number && call.created_at >= AnonymizedData::Constants::ANONYMIZATION_START_DATE) }
  end

  def users_phone_numbers
    facilities.flat_map(&:users).compact.map(&:phone_number).uniq
  end

  def appointments
    facilities.map { |fac| AnonymizedData::FacilityData.new(fac).appointment_data }.flatten
  end
end
