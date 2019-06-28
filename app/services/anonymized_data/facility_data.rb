class AnonymizedData::FacilityData
  attr_reader :facility, :appointments

  def initialize(facility)
    @facility = facility
    @appointments = appointment_data
  end

  def raw_data
    {
      AnonymizedData::Constants::PATIENTS_FILE =>
        patient_data,
      AnonymizedData::Constants::BPS_FILE =>
        bp_data,
      AnonymizedData::Constants::MEDICINES_FILE =>
        prescription_data,
      AnonymizedData::Constants::APPOINTMENTS_FILE =>
        appointments,
      AnonymizedData::Constants::SMS_REMINDERS_FILE =>
        communication_data(appointments),
      AnonymizedData::Constants::PHONE_CALLS_FILE =>
        phone_call_data(users_phone_numbers)
    }
  end

  def patient_data
    facility.patients.select do |p|
      p.device_created_at >= AnonymizedData::Constants::ANONYMIZATION_START_DATE
    end
  end

  def bp_data
    facility.blood_pressures.select do |bp|
      bp.device_created_at >= AnonymizedData::Constants::ANONYMIZATION_START_DATE
    end
  end

  def prescription_data
    facility.prescription_drugs.select do |pd|
      pd.device_created_at >= AnonymizedData::Constants::ANONYMIZATION_START_DATE
    end
  end

  def appointment_data
    facility.appointments.select do |app|
      app.device_created_at >= AnonymizedData::Constants::ANONYMIZATION_START_DATE
    end
  end

  def communication_data(appointments)
    appointments.flat_map(&:communications).select do |comm|
      comm.device_created_at >= AnonymizedData::Constants::ANONYMIZATION_START_DATE
    end
  end

  def phone_call_data(users_phone_numbers)
    CallLog.all.select do |call|
      users_phone_numbers.include?(call.caller_phone_number &&
                                     call.created_at >= AnonymizedData::Constants::ANONYMIZATION_START_DATE)
    end
  end

  def users_phone_numbers
    facility.users.compact.map(&:phone_number).uniq
  end
end
