class Api::V1::BloodPressuresController < Api::V1::SyncController
  def sync_from_user
    __sync_from_user__(blood_pressures_params)
  end

  def sync_to_user
    __sync_to_user__('blood_pressures')
  end

  private

  def merge_if_valid(blood_pressure_params)
    validator = Api::V1::BloodPressurePayloadValidator.new(blood_pressure_params)
    logger.debug "Blood Pressure had errors: #{validator.errors_hash}" if validator.invalid?
    if validator.invalid?
      NewRelic::Agent.increment_metric('Merge/BloodPressure/schema_invalid')
    else
      BloodPressure.merge(Api::V1::Transformer.from_request(blood_pressure_params))
    end

    validator.errors_hash if validator.invalid?
  end

  def find_records_to_sync(since, limit)
    BloodPressure.updated_on_server_since(since, limit)
  end

  def transform_to_response(blood_pressure)
    Api::V1::Transformer.to_response(blood_pressure)
  end

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
end
