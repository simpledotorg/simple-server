class Api::V1::PatientsController < APIController

  def sync_from_user
    errors = patient_params.reduce([]) do |errors, single_patient_params|
      patient = MergePatientService.new(single_patient_params).merge
      errors << patient.errors_hash if patient.has_errors?
      errors
    end

    response = { errors: errors.nil? ? nil : errors }
    render json: response, status: :ok
  end

  def sync_to_user
    latest_record_timestamp = params[:latest_record_timestamp].to_time
    patients_to_sync        = Patient.distinct
                                .left_outer_joins(:address)
                                .left_outer_joins(:phone_numbers)
                                .where('patients.updated_on_server_at >= ?
                                        or addresses.updated_on_server_at >= ?
                                        or phone_numbers.updated_on_server_at >= ?',
                                       latest_record_timestamp, latest_record_timestamp, latest_record_timestamp)
    render json: { patients: patients_to_sync.map(&:nested_hash) }, status: :ok
  end

  private

  def patient_params
    permitted_address_params      = %i[id street_address colony village district state country pin created_at updated_at]
    permitted_phone_number_params = %i[id number type active created_at updated_at]
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
        address:       permitted_address_params)
    end
  end
end
