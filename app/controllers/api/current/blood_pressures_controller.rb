class Api::Current::BloodPressuresController < Api::Current::SyncController
  include Api::Current::PrioritisableByFacility

  def sync_from_user
    __sync_from_user__(blood_pressures_params)
  end

  def sync_to_user
    __sync_to_user__('blood_pressures')
  end

  private

  def merge_if_valid(blood_pressure_params)
    validator = Api::Current::BloodPressurePayloadValidator.new(blood_pressure_params)
    logger.debug "Blood Pressure had errors: #{validator.errors_hash}" if validator.invalid?
    if validator.invalid?
      NewRelic::Agent.increment_metric('Merge/BloodPressure/schema_invalid')
      { errors_hash: validator.errors_hash }
    else
      blood_pressure = ActiveRecord::Base.transaction do
        set_patient_recorded_at(blood_pressure_params)
        transformed_params = Api::Current::BloodPressureTransformer.from_request(blood_pressure_params)
        BloodPressure.merge(transformed_params)
      end
      { record: blood_pressure }
    end
  end

  def set_patient_recorded_at(bp_params)
    return if bp_params['recorded_at'].present?

    patient = Patient.find_by(id: bp_params['patient_id'])
    return if patient.blank?

    patient.recorded_at = patient_recorded_at(bp_params, patient)
    patient.save
  end

  def patient_recorded_at(bp_params, patient)
    [bp_params['created_at'], patient.recorded_at].min
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
        :updated_at,
        :recorded_at,
        :deleted_at
      )
    end
  end
end
