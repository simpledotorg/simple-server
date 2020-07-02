class MoveUserRecordedDataToRegistrationFacility
  attr_reader :user, :source_facility, :destination_facility

  def initialize(user, source_facility, destination_facility)
    @user = user
    @source_facility = source_facility
    @destination_facility = destination_facility
  end

  def fix_patient_data
    patients = Patient.where(registration_user: user, registration_facility: source_facility)
    fix_pbi_metadata(patients)
    fix_data_for_relation(
      patients,
      registration_facility: destination_facility
    )
  end

  def fix_appointment_data
    fix_data_for_relation(
      Appointment.where(user: user, facility: source_facility),
      facility: destination_facility
    )
  end

  def fix_prescription_drug_data
    fix_data_for_relation(
      PrescriptionDrug.where(user: user, facility: source_facility),
      facility: destination_facility
    )
  end

  def fix_blood_pressure_data
    blood_pressures = BloodPressure.where(user: user, facility: source_facility)

    fix_data_for_relation(
      Encounter.includes(:observations)
               .where(observations: {observable_id: blood_pressures.pluck(:id)}),
      facility: destination_facility
    )

    fix_data_for_relation(
      blood_pressures,
      facility: destination_facility
    )
  end

  def fix_blood_sugar_data
    blood_sugars = BloodSugar.where(user: user, facility: source_facility)

    fix_data_for_relation(
      Encounter.includes(:observations)
               .where(observations: {observable_id: blood_sugars.pluck(:id)}),
      facility: destination_facility
    )
    fix_data_for_relation(
      blood_sugars,
      facility: destination_facility
    )
  end

  private

  def fix_data_for_relation(relation, update_hash)
    Rails.logger.info "Moving #{relation.count} #{relation.klass} records, for user: #{user.full_name},"\
                      "to #{destination_facility.name}"
    updated_records = relation.update(update_hash)
    updated_records.count
  end

  def fix_pbi_metadata(patients)
    patient_business_identifiers = patients.map(&:business_identifiers)
      .flatten
      .select { |pbi|
      pbi.metadata == {"assigning_user_id" => user.id,
                       "assigning_facility_id" => source_facility.id}
    }
    Rails.logger.info "Fixing metadata for #{patient_business_identifiers.count} PatientBusinessIdentifier records,"\
                      "for user: #{user.full_name}, changing assigning_facility_id to #{destination_facility.name}"
    updated_metadata = {"assigning_user_id": user.id, "assigning_facility_id": destination_facility.id}
    patient_business_identifiers.each do |pbi|
      pbi.update(metadata: updated_metadata)
    end
  end
end
