class Api::V4::QuestionnaireResponsePayloadValidator < Api::V3::PayloadValidator
  attr_accessor(
    :id,
    :questionnaire_id,
    :facility_id,
    :user_id,
    :content,
    :created_at,
    :updated_at,
    :deleted_at
  )

  validate :validate_schema
  validate :belongs_to_current_facility

  def schema
    Api::V4::Models.questionnaire_response
  end

  def belongs_to_current_facility
    # errors.add() if facility_id == current_facility.i
  end
end
