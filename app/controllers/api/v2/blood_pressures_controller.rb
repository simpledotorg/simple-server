class Api::V2::BloodPressuresController < Api::Current::BloodPressuresController
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
        :updated_at,
        :deleted_at
      )
    end
  end

  private

  def merge_if_valid(blood_pressure_params)
    validator = Api::Current::BloodPressurePayloadValidator.new(blood_pressure_params)
    logger.debug "Blood Pressure had errors: #{validator.errors_hash}" if validator.invalid?
    if validator.invalid?
      NewRelic::Agent.increment_metric('Merge/BloodPressure/schema_invalid')
      { errors_hash: validator.errors_hash }
    else
      blood_pressure = BloodPressure.merge(Api::V2::BloodPressureTransformer.from_request(blood_pressure_params))
      { record: blood_pressure }
    end
  end

  def transform_to_response(blood_pressure)
    Api::V2::BloodPressureTransformer.to_response(blood_pressure)
  end
end
