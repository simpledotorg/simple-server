class Api::V4::MedicationsController < Api::V4::SyncController
  include Api::V3::PublicApi

  def sync_to_user
    __sync_to_user__("drugs")
  end

  private

  def current_facility_records
    []
  end

  def other_facility_records
    time(__method__) do
      Medication.all
    end
  end

  def disable_audit_logs?
    true
  end

  def transform_to_response(drug)
    Api::V4::MedicationTransformer.to_response(drug)
  end

  def response_process_token
    {other_facilities_processed_since: processed_until(other_facility_records),
     resync_token: resync_token}
  end

  def processed_until(records)
    Time.current.strftime(APIController::TIME_WITHOUT_TIMEZONE_FORMAT) if records.any?
  end

  def force_resync?
    resync_token_modified?
  end

  def records_to_sync
    time(__method__) do
      other_facility_records
    end
  end
end
