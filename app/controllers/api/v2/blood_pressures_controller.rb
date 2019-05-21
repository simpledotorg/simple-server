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
    validator = Api::V2::BloodPressurePayloadValidator.new(blood_pressure_params)
    logger.debug "Blood Pressure had errors: #{validator.errors_hash}" if validator.invalid?
    if validator.invalid?
      NewRelic::Agent.increment_metric('Merge/BloodPressure/schema_invalid')
      { errors_hash: validator.errors_hash }
    else
      blood_pressure = BloodPressure.merge(Api::V2::BloodPressureTransformer.from_request(blood_pressure_params))
      retroactively_set_recorded_at(blood_pressure)
      { record: blood_pressure }
    end
  end

  def retroactively_set_recorded_at(blood_pressure)
    # older versions set device_created_at in the past
    blood_pressure.update_column(:recorded_at, blood_pressure.device_created_at)

    patient = blood_pressure.patient

    # blood pressures for a new patient might be
    # synced before the patient themselves
    return unless patient.present?

    # if patient's device_created_at is older than
    # the BP's we modify it to be the earliest BP's date
    if blood_pressure.device_created_at < patient.device_created_at
      earliest_blood_pressure = patient.blood_pressures.order(device_created_at: :asc).first
      patient.update_column(:recorded_at, earliest_blood_pressure.device_created_at)
    end
  end

  def transform_to_response(blood_pressure)
    Api::V2::BloodPressureTransformer.to_response(blood_pressure)
  end
end
