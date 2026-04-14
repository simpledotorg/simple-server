class Api::V4::PatientScoresController < Api::V4::SyncController
  def sync_to_user
    __sync_to_user__("patient_scores")
  end

  def current_facility_records
    @current_facility_records ||=
      keyset_paginate(
        PatientScore
          .for_sync
          .where(patient: current_facility.prioritized_patients.select(:id)),
        current_facility_processed_since,
        current_facility_last_id,
        limit
      ).to_a
  end

  def other_facility_records
    other_facilities_limit = limit - current_facility_records.size
    @other_facility_records ||=
      keyset_paginate(
        PatientScore
          .for_sync
          .where(patient_id: current_sync_region
                               .syncable_patients
                               .where.not(registration_facility: current_facility)
                               .select(:id)),
        other_facilities_processed_since,
        other_facilities_last_id,
        other_facilities_limit
      ).to_a
  end

  private

  def transform_to_response(patient_score)
    Api::V4::PatientScoreTransformer.to_response(patient_score)
  end

  def keyset_paginate(scope, since_time, since_id, batch_limit)
    return scope.none if batch_limit <= 0

    ordered = scope.order(:updated_at, :id).limit(batch_limit)

    if since_id.present?
      ordered.where(
        "(patient_scores.updated_at, patient_scores.id) > (?, ?)",
        since_time, since_id
      )
    else
      ordered.where("patient_scores.updated_at >= ?", since_time)
    end
  end

  def processed_until(records)
    return nil if records.empty?
    last = records.last
    {
      timestamp: last.updated_at.strftime(APIController::TIME_WITHOUT_TIMEZONE_FORMAT),
      id: last.id
    }
  end

  def response_process_token
    current_cursor = processed_until(current_facility_records)
    other_cursor = processed_until(other_facility_records)

    {
      current_facility_id: current_facility.id,
      current_facility_processed_since:
        current_cursor&.dig(:timestamp) || process_token[:current_facility_processed_since],
      current_facility_last_id:
        current_cursor&.dig(:id) || process_token[:current_facility_last_id],
      other_facilities_processed_since:
        other_cursor&.dig(:timestamp) || process_token[:other_facilities_processed_since],
      other_facilities_last_id:
        other_cursor&.dig(:id) || process_token[:other_facilities_last_id],
      resync_token: resync_token,
      sync_region_id: current_sync_region.id
    }
  end

  def current_facility_last_id
    return nil if force_resync?
    return nil if process_token[:current_facility_id] != current_facility.id
    process_token[:current_facility_last_id]
  end

  def other_facilities_last_id
    return nil if force_resync?
    process_token[:other_facilities_last_id]
  end
end
