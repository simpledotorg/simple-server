class Api::V1::PatientsController < Api::V1::SyncController
  def sync_from_user
    __sync_from_user__(patients_params)
  end

  def sync_to_user
    __sync_to_user__('patients')
  end

  private

  def merge_if_valid(single_patient_params)
    validator = Api::V1::PatientPayloadValidator.new(single_patient_params)
    logger.debug "Patient had errors: #{validator.errors_hash}" if validator.invalid?
    if validator.invalid?
      NewRelic::Agent.increment_metric('Merge/Patient/schema_invalid')
    else
      MergePatientService.new(
        Api::V1::PatientTransformer.from_nested_request(single_patient_params)
      ).merge
    end

    validator.errors_hash if validator.invalid?
  end

  def find_records_to_sync(since, limit)
    Patient.updated_on_server_since(since, limit)
  end

  def transform_to_response(patient)
    Api::V1::PatientTransformer.to_nested_response(patient)
  end

  def patients_params
    permitted_address_params      = %i[id street_address village_or_colony district state country pin created_at updated_at]
    permitted_phone_number_params = %i[id number phone_type active created_at updated_at]

    params.require(:patients).map do |single_patient_params|
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
        phone_numbers: [permitted_phone_number_params],
        address:       permitted_address_params
      )
    end
  end
end
