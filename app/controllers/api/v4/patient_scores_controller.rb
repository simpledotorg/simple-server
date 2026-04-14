class Api::V4::PatientScoresController < Api::V4::SyncController
  def sync_to_user
    __sync_to_user__("patient_scores")
  end

  def current_facility_records
    @current_facility_records ||=
      PatientScore
        .for_sync
        .where(patient: current_facility.prioritized_patients.select(:id))
        .order(:updated_at, :id)
        .limit(limit)
        .offset((current_page - 1) * limit)
        .to_a
  end

  def other_facility_records
    []
  end

  private

  def transform_to_response(patient_score)
    Api::V4::PatientScoreTransformer.to_response(patient_score)
  end

  def current_page
    page = process_token[:next_page].to_i
    page < 1 ? 1 : page
  end

  def response_process_token
    {
      current_facility_id: current_facility.id,
      next_page: current_facility_records.empty? ? 1 : current_page + 1,
      resync_token: resync_token,
      sync_region_id: current_sync_region.id
    }
  end
end
