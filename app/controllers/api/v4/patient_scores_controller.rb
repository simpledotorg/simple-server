class Api::V4::PatientScoresController < Api::V4::SyncController
  def sync_to_user
    __sync_to_user__("patient_scores")
  end

  def current_facility_records
    @current_facility_records ||=
      PatientScore
        .for_sync
        .where(patient: current_facility.prioritized_patients.select(:id))
        .updated_on_server_since(current_facility_processed_since, limit)
  end

  def other_facility_records
    other_facilities_limit = limit - current_facility_records.size
    @other_facility_records ||=
      PatientScore
        .for_sync
        .where(patient_id: current_sync_region
          .syncable_patients
          .where.not(registration_facility: current_facility)
          .select(:id))
        .updated_on_server_since(other_facilities_processed_since, other_facilities_limit)
  end

  private

  def transform_to_response(patient_score)
    Api::V4::PatientScoreTransformer.to_response(patient_score)
  end
end
