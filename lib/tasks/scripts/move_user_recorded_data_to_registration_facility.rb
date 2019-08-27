class MoveUserRecordedDataToRegistrationFacility

  attr_reader :user, :source_facility, :destination_facility

  def initialize(user, source_facility, destination_facility)
    @user = user
    @source_facility = source_facility
    @destination_facility = destination_facility
  end

  def fix_patient_data
    fix_data_for_relation(
      Patient.where(registration_user: user, registration_facility: source_facility),
      registration_facility: destination_facility)
  end

  def fix_blood_pressure_data
    fix_data_for_relation(
      BloodPressure.where(user: user, facility: source_facility),
      facility: destination_facility)
  end

  def fix_appointment_data
    user_appointment_ids = AuditLog.where(action: 'create', auditable_type: 'Appointment', user: user).pluck(:auditable_id)
    fix_data_for_relation(
      Appointment.where(id: user_appointment_ids, facility: source_facility),
      facility: destination_facility
    )
  end

  def fix_prescription_drug_data
    user_prescription_drug_ids = AuditLog.where(action: 'create', auditable_type: 'PrescriptionDrug', user: user).pluck(:auditable_id)
    fix_data_for_relation(
      PrescriptionDrug.where(id: user_prescription_drug_ids, facility: source_facility),
      facility: destination_facility
    )
  end

  private

  def fix_data_for_relation(relation, update_hash)
    Rails.logger.info "Moving #{relation.count} #{relation.klass.to_s} records, for user: #{user.full_name}, to #{destination_facility.name}"
    updated_records = relation.update(update_hash)
    updated_records.count
  end
end