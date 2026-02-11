class Api::V4::PatientScoresController < Api::V4::SyncController
  def sync_to_user
    __sync_to_user__("patient_scores")
  end

  private

  def transform_to_response(patient_score)
    Api::V4::PatientScoreTransformer.to_response(patient_score)
  end
end
