class Api::Current::EncountersController < Api::Current::SyncController
  def sync_from_user
    __sync_from_user__(encounter_params)
  end

  def sync_to_user
    __sync_to_user__('encounters')
  end

  private

  def merge_if_valid(encounter_params)
    validator = Api::Current::EncounterPayloadValidator.new(encounter_params)
    logger.debug "Encounter had errors: #{validator.errors_hash}" if validator.invalid?
    if validator.invalid?
      NewRelic::Agent.increment_metric('Merge/Encounter/schema_invalid')
      { errors_hash: validator.errors_hash }
    else
      transformed_params = Api::Current::EncounterTransformer.from_nested_request(encounter_params)
      { record: merge(transformed_params) }
    end
  end

  def merge(params)
    encounter_merge_params = params.except(:observations).merge(facility: current_facility,
                                                                recorded_at: params[:device_created_at])
    encounter = Encounter.merge(encounter_merge_params)

    params[:observations][:blood_pressures].map do |bp|
      observable = BloodPressure.merge(bp).encounter_event
      observable.update(encounter: encounter, user: current_user)
    end

    params[:observations][:prescription_drugs]&.map do |pd|
      observable = PrescriptionDrug.merge(pd).encounter_event
      observable.update!(encounter: encounter, user: current_user)
    end

    encounter
  end

  def transform_to_response(encounter)
    Api::Current::EncounterTransformer.to_nested_response(encounter)
  end

  def encounter_params
    permitted_bp_params = %i[id systolic diastolic patient_id facility_id user_id created_at updated_at recorded_at deleted_at]

    params.require(:encounters).map do |encounter_params|
      encounter_params.permit(
        :id,
        :patient_id,
        :created_at,
        :updated_at,
        :recorded_at,
        :deleted_at,
        observations: [:"blood_pressures" => [permitted_bp_params]],
      )
    end
  end
end
