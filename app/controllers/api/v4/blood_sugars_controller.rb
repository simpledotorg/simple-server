class Api::V4::BloodSugarsController < Api::V3::BloodSugarsController

  private

  def facility_group_records
    current_facility_group.blood_sugars.with_discarded
  end

  def merge_if_valid(blood_sugar_params)
    validator = Api::V4::BloodSugarPayloadValidator.new(blood_sugar_params)
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
end
