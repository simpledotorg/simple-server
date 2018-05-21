class Api::V1::PatientsController < APIController
  def sync_from_user
    errors = patients_params.reduce([]) do |errors, single_patient_params|
      patient = MergePatientService.new(single_patient_params).merge
      errors << patient.errors_hash if patient.invalid?
      errors
    end

    response = { errors: errors.nil? ? nil : errors }
    render json: response, status: :ok
  end

  def sync_to_user
    patients_to_sync             = Patient.updated_on_server_since(latest_record_timestamp, number_of_records)
    next_latest_record_timestamp = patients_to_sync.last.updated_on_server_at

    render json:   { patients:                patients_to_sync.map(&:nested_hash),
                     latest_record_timestamp: next_latest_record_timestamp },
           status: :ok
  end

  private

  def patients_params
    permitted_address_params      = %i[id street_address colony village district state country pin created_at updated_at]
    permitted_phone_number_params = %i[id number phone_type active created_at updated_at]

    params.require(:patients).map do |single_patient_params|
      single_patient_params.permit(
        :id,
        :full_name,
        :age_when_created,
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

  def latest_record_timestamp
    if params[:first_time].present? && params[:first_time] == 'true'
      Time.new(0)
    else
      params.require(:latest_record_timestamp).to_time
    end
  end

  def number_of_records
    if params[:number_of_records].present?
      params[:number_of_records].to_i
    else
      10 # todo: extract this into config
    end
  end
end