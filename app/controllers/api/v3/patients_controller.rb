class Api::V3::PatientsController < Api::V3::SyncController
  def sync_from_user
    __sync_from_user__(patients_params)
  end

  def sync_to_user
    unscope_associations do
      __sync_to_user__("patients")
    end
  end

  def request_metadata
    {request_user_id: current_user.id, request_facility_id: current_facility.id}
  end

  def current_facility_records
    time(__method__) do
      @current_facility_records ||=
        current_facility
          .prioritized_patients
          .for_sync
          .updated_on_server_since(current_facility_processed_since, limit)
    end
  end

  def other_facility_records
    time(__method__) do
      other_facilities_limit = limit - current_facility_records.size
      @other_facility_records ||=
        current_sync_region.syncable_patients
          .where.not(registration_facility: current_facility)
          .for_sync
          .updated_on_server_since(other_facilities_processed_since, other_facilities_limit)
    end
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
    validator_params = single_patient_params.merge(request_user_id: current_user.id)
    validator = Api::V3::PatientPayloadValidator.new(validator_params)

    if validator.check_invalid?
      logger.debug "Patient had errors: #{validator.errors_hash}"
      {errors_hash: validator.errors_hash}
    else
      transformed_params = Api::V3::PatientTransformer.from_nested_request(single_patient_params)
      patient = MergePatientService.new(transformed_params, request_metadata: request_metadata).merge
      log_identical_record_info(patient) if patient.merge_status == :identical
      {record: patient}
    end
  end

  def log_identical_record_info(patient)
    # This is to investigate large number of identical records being synced by the app.
    # Remove once we figure it out.
    logger.info(event: "identical patient record synced",
      user_id: current_user.id,
      patient_id: patient.id,
      sync_region_id: current_sync_region.id)
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
