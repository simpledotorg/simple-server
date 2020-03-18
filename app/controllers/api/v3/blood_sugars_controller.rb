class Api::V3::BloodSugarsController < Api::V3::SyncController
  include Api::V3::PrioritisableByFacility
  include Api::V3::SyncEncounterObservation
  include Api::V3::RetroactiveDataEntry

  def sync_from_user
    __sync_from_user__(blood_sugars_params)
  end

  def sync_to_user
    __sync_to_user__('blood_sugars')
  end

  private

  def facility_group_records
    current_facility_group.blood_sugars.with_discarded.without_hba1c
  end

  def transform_to_response(blood_sugar)
    Api::V3::Transformer.to_response(blood_sugar)
  end

  def merge_if_valid(blood_sugar_params)
    validator = Api::V3::BloodSugarPayloadValidator.new(blood_sugar_params)
    logger.debug "Blood Sugar payload had errors: #{validator.errors_hash}" if validator.invalid?
    if validator.invalid?
      NewRelic::Agent.increment_metric('Merge/BloodSugar/schema_invalid')
      { errors_hash: validator.errors_hash }
    else
      set_patient_recorded_at(blood_sugar_params)
      transformed_params = Api::V3::Transformer.from_request(blood_sugar_params)
      { record: merge_encounter_observation(:blood_sugars, transformed_params) }
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
end
