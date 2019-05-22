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
      ActiveRecord::Base.transaction do
        transformed_blood_pressure_params = retroactively_set_recorded_at(Api::V2::BloodPressureTransformer.from_request(blood_pressure_params))
        blood_pressure = BloodPressure.merge(transformed_blood_pressure_params)
        { record: blood_pressure }
      end
    end
  end

  def retroactively_set_recorded_at(blood_pressure_params)
    # older versions set device_created_at in the past
    blood_pressure_params['recorded_at'] = blood_pressure_params['device_created_at']

    patient = Patient.find_by(id: blood_pressure_params['patient_id'])

    # blood pressures for a new patient might be
    # synced before the patient themselves
    return unless patient.present?

    # if patient's device_created_at is older than
    # the BP's we modify it to be the earliest BP's date
    if blood_pressure_params['recorded_at'] < patient.recorded_at
      earliest_blood_pressure_in_db = patient.blood_pressures.order(recorded_at: :asc).first
      earliest_blood_pressure_recorded_at = if blood_pressure_params['recorded_at'] < earliest_blood_pressure_in_db.recorded_at
                                              blood_pressure_params['recorded_at']
                                            else
                                              earliest_blood_pressure_in_db.recorded_at
                                            end
      patient.update_column(:recorded_at, earliest_blood_pressure_recorded_at)
    end

    blood_pressure_params
  end

  def transform_to_response(blood_pressure)
    Api::V2::BloodPressureTransformer.to_response(blood_pressure)
  end
end
