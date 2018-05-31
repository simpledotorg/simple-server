class Api::V1::BloodPressuresController < APIController
  def merge_blood_pressure(blood_pressure_params)
    validator = Api::V1::BloodPressurePayloadValidator.new(blood_pressure_params)
    logger.debug "Blood Pressure had errors: #{validator.errors_hash}" if validator.invalid?
    unless validator.invalid?
      BloodPressure.merge(Api::V1::Transformer.from_request(blood_pressure_params))
    end

    validator.errors_hash if validator.invalid?
  end

  def sync_from_user
    errors = blood_pressures_params.flat_map { |blood_pressure_params| merge_blood_pressure(blood_pressure_params) || [] }

    response = { errors: errors.nil? ? nil : errors }
    render json: response, status: :ok
  end

  def sync_to_user
    blood_pressures_to_sync = BloodPressure.updated_on_server_since(processed_since, limit)

    most_recent_record_timestamp =
      if blood_pressures_to_sync.empty?
        processed_since
      else
        blood_pressures_to_sync.last.updated_at
      end

    render(
      json:   {
        blood_pressures: blood_pressures_to_sync.map { |blood_pressure| Api::V1::Transformer.to_response(blood_pressure) },
        processed_since: most_recent_record_timestamp.strftime(TIME_WITHOUT_TIMEZONE_FORMAT)
      },
      status: :ok
    )
  end

  private

  def blood_pressures_params
    params.require(:blood_pressures).map do |blood_pressure_params|
      blood_pressure_params.permit(
        :id,
        :systolic,
        :diastolic,
        :patient_id,
        :created_at,
        :updated_at
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
