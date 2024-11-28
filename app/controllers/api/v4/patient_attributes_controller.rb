class Api::V4::PatientAttributesController < Api::V4::SyncController
  def sync_from_user
    __sync_from_user__(patient_attributes_params)
  end

  def sync_to_user
    __sync_to_user__("patient_attributes")
  end

  def metadata
    {user_id: current_user.id}
  end

  private

  def merge_if_valid(payload_attribute_params)
    validator = Api::V4::PatientAttributePayloadValidator.new(payload_attribute_params)
    logger.debug "BMI sync had errors: #{validator.errors_hash}" if validator.invalid?
    if validator.check_invalid?
      {errors_hash: validator.errors_hash}
    else
      record_params = Api::V4::PatientAttributeTransformer
        .from_request(payload_attribute_params)
        .merge(metadata)

      {record: PatientAttribute.merge(record_params)}
    end
  end

  def transform_to_response(patient_attribute)
    Api::V4::PatientAttributeTransformer.to_response(patient_attribute)
  end

  def patient_attributes_params
    params.require(:patient_attributes).map do |patient_attribute_params|
      patient_attribute_params.permit(
        :id,
        :patient_id,
        :height,
        :weight,
        :height_unit,
        :weight_unit,
        :created_at,
        :updated_at
      )
    end
  end
end
