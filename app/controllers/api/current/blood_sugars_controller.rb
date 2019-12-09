class Api::Current::BloodSugarsController < Api::Current::SyncController
  include Api::Current::PrioritisableByFacility
  include Api::Current::SyncEncounter

  def sync_from_user
    __sync_from_user__(blood_sugars_params)
  end

  def sync_to_user
    __sync_to_user__('blood_sugars')

  end

  private

  def transform_to_response(blood_sugar)
    Api::Current::Transformer.to_response(blood_sugar)
  end

  def merge_if_valid(blood_sugar_params)
    validator = Api::Current::BloodSugarPayloadValidator.new(blood_sugar_params)
    logger.debug "Blood Sugar payload had errors: #{validator.errors_hash}" if validator.invalid?
    if validator.invalid?
      NewRelic::Agent.increment_metric('Merge/BloodSugar/schema_invalid')
      { errors_hash: validator.errors_hash }
    else
      blood_sugar = ActiveRecord::Base.transaction do
        set_patient_recorded_at(blood_sugar_params)
        transformed_params = Api::Current::Transformer.from_request(blood_sugar_params)

        if FeatureToggle.enabled?('SYNC_ENCOUNTERS')
          # this will always return a single blood_sugar
          add_encounter_and_merge_record(:blood_sugars, transformed_params)[:observations][:blood_sugars][0]
        else
          BloodSugar.merge(transformed_params)
        end
      end
      { record: blood_sugar }
    end
  end

  def blood_sugars_params
    params.require(:blood_sugars).map do |blood_sugar_params|
      blood_sugar_params.permit(
        :id,
        :blood_sugar_type,
        :blood_sugar_value,
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



  def set_patient_recorded_at(params)
    # We don't set the patient recorded if retroactive data-entry is supported by the app
    # If the app supports retroactive data-entry, we expect the app to update the patients and sync
    return if params['recorded_at'].present?

    patient = Patient.find_by(id: params['patient_id'])
    # If the patient is not synced yet, we simply ignore setting patient's recorded_at
    return if patient.blank?

    # We only try to set the patient's recorded_at when retroactive data-entry is not supported on the app
    patient.recorded_at = patient_recorded_at(params, patient)
    patient.save
  end
end