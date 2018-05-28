class Api::V1::PatientsController < APIController
  def merge_patient(single_patient_params)
    patient_payload = Api::V1::PatientPayload.new(single_patient_params.to_hash.with_indifferent_access)
    if patient_payload.invalid?
      patient_payload.errors_hash
    else
      patient = MergePatientService.new(patient_payload.model_attributes).merge
      patient.errors_hash if patient.invalid?
    end
  end

  def sync_from_user
    errors = patients_params.flat_map { |single_patient_params| merge_patient(single_patient_params) || [] }

    response = { errors: errors.nil? ? nil : errors }
    render json: response, status: :ok
  end

  def sync_to_user
    patients_to_sync = Patient.updated_on_server_since(processed_since, limit)

    most_recent_record_timestamp =
      if patients_to_sync.empty?
        processed_since
      else
        patients_to_sync.last.updated_at
      end

    render(
      json:   {
        patients:        patients_to_sync.map(&:nested_hash),
        processed_since: most_recent_record_timestamp.strftime('%FT%T.%3NZ')
      },
      status: :ok
    )
  end

  private

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

  def processed_since
    params[:processed_since].try(:to_time) || Time.new(0)
  end

  def limit
    if params[:limit].present?
      params[:limit].to_i
    else
      ENV['DEFAULT_NUMBER_OF_RECORDS'].to_i
    end
  end
end
