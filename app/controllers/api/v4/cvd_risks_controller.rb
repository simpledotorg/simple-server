class Api::V4::CvdRisksController < Api::V4::SyncController
  include Api::V3::SyncEncounterObservation
  include Api::V3::RetroactiveDataEntry

  def sync_from_user
    __sync_from_user__(cvd_risk_params)
  end

  def sync_to_user
    __sync_to_user__("cvd_risks")
  end

  private

  def merge_if_valid(payload)
    validator = Api::V4::CvdRiskPayloadValidator.new(payload)
    logger.debug "CVD Risk sync had errors: #{validator.errors_hash}" if validator.invalid?
    if validator.check_invalid?
      {errors_hash: validator.errors_hash}
    else
      record_params = Api::V4::CvdRiskTransformer
        .from_request(payload)

      {record: CvdRisk.merge(record_params)}
    end
  end

  def transform_to_response(payload)
    Api::V4::CvdRiskTransformer.to_response(payload)
  end

  def cvd_risk_params
    params.require(:cvd_risks).map do |cvd_risk_params|
      cvd_risk_params.permit(
        :id,
        :patient_id,
        :risk_score,
        :deleted_at,
        :created_at,
        :updated_at
      )
    end
  end
end
