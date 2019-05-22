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
      blood_pressure = ActiveRecord::Base.transaction do
        transformed_params =
          set_default_recorded_at(Api::V2::BloodPressureTransformer.from_request(blood_pressure_params))

        set_patient_recorded_at_retroactively(transformed_params)
        BloodPressure.merge(transformed_params)
      end

      { record: blood_pressure }
    end
  end

  def set_default_recorded_at(blood_pressure_params)
    # older versions set device_created_at in the past
    blood_pressure_params.merge('recorded_at' => blood_pressure_params['device_created_at'])
  end

  def set_patient_recorded_at_retroactively(blood_pressure_params)
    # blood pressures for a new patient might be
    # synced before the patient themselves
    patient = Patient.find_by(id: blood_pressure_params['patient_id'])
    return if patient.blank?

    patient.update_column(:recorded_at, patient_recorded_at(patient, blood_pressure_params))
  end

  def patient_recorded_at(patient, blood_pressure_params)
    blood_pressure_params['recorded_at'] < patient.recorded_at ?
      blood_pressure_params['recorded_at'] :
      patient.recorded_at
  end

  def transform_to_response(blood_pressure)
    Api::V2::BloodPressureTransformer.to_response(blood_pressure)
  end
end
