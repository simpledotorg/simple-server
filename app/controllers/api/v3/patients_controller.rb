class Api::V3::PatientsController < Api::V3::SyncController
  def sync_from_user
    __sync_from_user__(patients_params)
  end

  def sync_to_user
    unscope_associations do
      __sync_to_user__("patients")
    end
  end

  def metadata(patient_params)
    {
      registration_user_id: current_user.id,
      registration_facility_id: registration_facility_id(patient_params)
    }
  end

  def registration_facility_id(patient_params)
    patient_params[:registration_facility_id].presence || current_facility.id
  end

  def current_facility_records
    facility_group_records
      .includes(:address, :phone_numbers, :business_identifiers)
      .where(registration_facility: current_facility)
      .updated_on_server_since(current_facility_processed_since, limit)
  end

  def other_facility_records
    other_facilities_limit = limit - current_facility_records.count
    facility_group_records
      .includes(:address, :phone_numbers, :business_identifiers)
      .where.not(registration_facility: current_facility.id)
      .updated_on_server_since(other_facilities_processed_since, other_facilities_limit)
  end

  private

  def unscope_associations
    Address.unscoped do
      PatientPhoneNumber.unscoped do
        PatientBusinessIdentifier.unscoped do
          yield
        end
      end
    end
  end

  def merge_if_valid(single_patient_params)
    metadata = metadata(single_patient_params)
    params = single_patient_params.merge(metadata)
    validator = Api::V3::PatientPayloadValidator.new(params)

    if validator.invalid?
      logger.debug "Patient had errors: #{validator.errors_hash}"
      NewRelic::Agent.increment_metric("Merge/Patient/schema_invalid")
      {errors_hash: validator.errors_hash}
    else
      transformed_params = Api::V3::PatientTransformer.from_nested_request(params)
      patient = MergePatientService.new(transformed_params, metadata_keys: metadata.keys).merge
      {record: patient}
    end
  end

  def transform_to_response(patient)
    Api::V3::PatientTransformer.to_nested_response(patient)
  end

  def patients_params
    permitted_address_params = %i[
      id
      street_address
      village_or_colony
      zone
      district
      state
      country
      pin
      created_at
      updated_at
    ]

    permitted_phone_number_params = %i[
      id
      number
      phone_type
      active
      created_at
      updated_at
    ]

    permitted_business_identifier_params = %i[
      id
      identifier
      identifier_type
      metadata
      metadata_version
      created_at
      updated_at
      deleted_at
    ]

    patient_attributes = params.require(:patients)
    patient_attributes.map do |single_patient_params|
      single_patient_params.permit(
        :id,
        :full_name,
        :age,
        :age_updated_at,
        :gender,
        :status,
        :date_of_birth,
        :created_at,
        :updated_at,
        :recorded_at,
        :reminder_consent,
        :deleted_at,
        :deleted_reason,
        :registration_facility_id,
        :assigned_facility_id,
        phone_numbers: [permitted_phone_number_params],
        address: permitted_address_params,
        business_identifiers: [permitted_business_identifier_params]
      )
    end
  end
end
