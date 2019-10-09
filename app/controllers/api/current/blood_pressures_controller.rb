class Api::Current::BloodPressuresController < Api::Current::SyncController
  include Api::Current::PrioritisableByFacility

  def sync_from_user
    __sync_from_user__(blood_pressures_params)
  end

  def sync_to_user
    __sync_to_user__('blood_pressures')
  end

  private

  def merge_if_valid(bp_params)
    validator = Api::Current::BloodPressurePayloadValidator.new(bp_params)
    logger.debug "Blood Pressure had errors: #{validator.errors_hash}" if validator.invalid?
    if validator.invalid?
      NewRelic::Agent.increment_metric('Merge/BloodPressure/schema_invalid')
      { errors_hash: validator.errors_hash }
    else
      blood_pressure = ActiveRecord::Base.transaction do
        set_patient_recorded_at(bp_params)
        transformed_params = Api::Current::BloodPressureTransformer.from_request(bp_params)

        if FeatureToggle.enabled?('CREATE_ENCOUNTERS_FROM_BPS')
          # this will always return a single blood_pressure
          add_encounter_and_merge_bp(transformed_params)[:observations][:blood_pressures][0]
        else
          BloodPressure.merge(transformed_params)
        end
      end
      { record: blood_pressure }
    end
  end

  def add_encounter_and_merge_bp(bp_params)
    encountered_on = Encounter.generate_encountered_on(bp_params[:recorded_at], current_timezone_offset)

    encounter_merge_params = {
      id: Encounter.generate_id(bp_params[:facility_id], bp_params[:patient_id], encountered_on),
      patient_id: bp_params[:patient_id],
      device_created_at: bp_params[:device_created_at],
      device_updated_at: bp_params[:device_updated_at],
      encountered_on: encountered_on,
      timezone_offset: current_timezone_offset,
      observations: {
        blood_pressures: [bp_params],
      }
    }.with_indifferent_access

    MergeEncounterService.new(encounter_merge_params, current_facility, current_user, current_timezone_offset).merge
  end

  def set_patient_recorded_at(bp_params)
    # We don't set the patient recorded if retroactive data-entry is supported by the app
    # If the app supports retroactive data-entry, we expect the app to update the patients and sync
    return if bp_params['recorded_at'].present?

    patient = Patient.find_by(id: bp_params['patient_id'])
    # If the patient is not synced yet, we simply ignore setting patient's recorded_at
    return if patient.blank?

    # We only try to set the patient's recorded_at when retroactive data-entry is not supported on the app
    patient.recorded_at = patient_recorded_at(bp_params, patient)
    patient.save
  end

  #
  # Patient recorded_at is the earlier of the two:
  #   1. Patient's earliest recorded blood pressure
  #   2. Patient's device_created_at
  #   3. The device_created_at of the current blood pressure being synced
  #
  def patient_recorded_at(bp_params, patient)
    earliest_blood_pressure = patient.blood_pressures.order(recorded_at: :asc).first
    [bp_params['created_at'], earliest_blood_pressure&.recorded_at, patient.device_created_at].compact.min
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
