class Api::Current::BloodPressuresController < Api::Current::SyncController
  def sync_from_user
    __sync_from_user__(blood_pressures_params)
  end

  def sync_to_user
    __sync_to_user__('blood_pressures')
  end

  def current_facility_records
    model_name
      .where(facility: current_facility)
      .updated_on_server_since(current_facility_processed_since, limit)
  end

  def other_facility_records
    other_facilities_limit = limit - current_facility_records.count
    model_name
      .where.not(facility: current_facility)
      .updated_on_server_since(other_facilities_processed_since, other_facilities_limit)
  end

  private

  def merge_if_valid(blood_pressure_params)
    validator = Api::Current::BloodPressurePayloadValidator.new(blood_pressure_params)
    logger.debug "Blood Pressure had errors: #{validator.errors_hash}" if validator.invalid?
    if validator.invalid?
      NewRelic::Agent.increment_metric('Merge/BloodPressure/schema_invalid')
      { errors_hash: validator.errors_hash }
    else
      blood_pressure = BloodPressure.merge(Api::Current::Transformer.from_request(blood_pressure_params))
      { record: blood_pressure }
    end
  end

  def transform_to_response(blood_pressure)
    Api::Current::Transformer.to_response(blood_pressure)
  end

  def blood_pressures_params
    params.require(:blood_pressures).map do |blood_pressure_params|
      blood_pressure_params.permit(
        :id,
        :systolic,
        :diastolic,
        :patient_id,
        :facility_id,
        :user_id,
        :created_at,
        :updated_at
      )
    end
  end
end
