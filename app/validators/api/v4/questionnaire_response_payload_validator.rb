class Api::V4::QuestionnaireResponsePayloadValidator < Api::V3::PayloadValidator
  attr_accessor(
    :id,
    :questionnaire_id,
    :questionnaire_type,
    :facility_id,
    :user_id,
    :content,
    :created_at,
    :updated_at,
    :deleted_at
  )

  validate :validate_schema

  def schema
    Api::V4::Models.questionnaire_response
  end
end
