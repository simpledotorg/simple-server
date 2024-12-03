class Api::V4::CvdRiskPayloadValidator < Api::V4::PayloadValidator
  attr_accessor :id, :patient_id, :risk_score, :created_at, :updated_at

  validate :validate_schema

  def schema
    Api::V4::Models.cvd_risk
  end
end
