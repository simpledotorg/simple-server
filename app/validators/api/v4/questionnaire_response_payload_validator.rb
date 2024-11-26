class Api::V4::QuestionnaireResponsePayloadValidator < Api::V4::PayloadValidator
  attr_accessor(
    :id,
    :questionnaire_id,
    :questionnaire_type,
    :facility_id,
    :last_updated_by_user_id,
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
