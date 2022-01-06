# frozen_string_literal: true

class MoveFacilityData
  attr_reader :user, :source_facility, :destination_facility

  def initialize(source_facility, destination_facility, user: nil)
    @user = user
    @source_facility = source_facility
    @destination_facility = destination_facility
  end

  def move_data
    {
      patient_count: fix_patient_data,
      bp_count: fix_blood_pressure_data,
      bs_count: fix_blood_sugar_data,
      appointment_count: fix_appointment_data,
      prescription_drug_count: fix_prescription_drug_data,
      teleconsultation_count: fix_teleconsultation_data
    }
  end

  def fix_patient_data
    registered_patients = records_to_move(
      Patient,
      user_key: :registration_user,
      facility_key: :registration_facility
    )
    fix_pbi_metadata(registered_patients)
    fix_data_for_relation(registered_patients, facility_key: :registration_facility)

    assigned_patients = records_to_move(
      Patient,
      user_key: :registration_user,
      facility_key: :assigned_facility
    )
    fix_data_for_relation(assigned_patients, facility_key: :assigned_facility)
  end

  def fix_appointment_data
    fix_data_for_relation(records_to_move(Appointment))
  end

  def fix_prescription_drug_data
    fix_data_for_relation(records_to_move(PrescriptionDrug))
  end

  def fix_blood_pressure_data
    blood_pressures = records_to_move(BloodPressure)

    fix_data_for_relation(
      Encounter
        .includes(:observations)
        .where(observations: {observable_id: blood_pressures.pluck(:id)})
    )

    fix_data_for_relation(blood_pressures)
  end

  def fix_blood_sugar_data
    blood_sugars = records_to_move(BloodSugar)

    fix_data_for_relation(
      Encounter
        .includes(:observations)
        .where(observations: {observable_id: blood_sugars.pluck(:id)})
    )
    fix_data_for_relation(blood_sugars)
  end

  def fix_teleconsultation_data
    fix_data_for_relation(records_to_move(Teleconsultation, user_key: :requester_id))
  end

  private

  def fix_data_for_relation(relation, facility_key: :facility)
    Rails.logger.info "Moving #{facility_key} of #{relation.count} #{relation.klass} records"\
                      "to #{destination_facility.name}"
    updated_records = relation.update(facility_key => destination_facility)
    updated_records.count
  end

  def records_to_move(klass, user_key: :user, facility_key: :facility)
    records = klass.where(facility_key => source_facility)

    return records.where(user_key => user) if user.present?
    records
  end

  def fix_pbi_metadata(patients)
    metadata_to_select_identifiers = {"assigning_facility_id" => source_facility.id}
    metadata_to_select_identifiers["assigning_user_id"] = user.id if user.present?

    patient_business_identifiers =
      patients
        .flat_map(&:business_identifiers)
        .select { |pbi| (metadata_to_select_identifiers.to_a - pbi.metadata.to_a).empty? }

    Rails.logger.info "Fixing metadata for #{patient_business_identifiers.count} PatientBusinessIdentifier records,"\
                      "changing assigning_facility_id to #{destination_facility.name}"

    patient_business_identifiers.each do |pbi|
      pbi.update(metadata: metadata_to_select_identifiers.merge("assigning_facility_id" => destination_facility.id))
    end
  end
end
