class Api::V4::MedicationsController < Api::V4::SyncController
  include Api::V3::PublicApi

  def sync_to_user
    __sync_to_user__("medications")
  end

  private

  def disable_audit_logs?
    true
  end

  def transform_to_response(medication)
    Api::V4::MedicationTransformer.to_response(medication)
  end

  def response_process_token
    {
      processed_since: processed_until(records_to_sync),
      resync_token: resync_token
    }
  end

  def processed_until(records)
    Time.current.strftime(APIController::TIME_WITHOUT_TIMEZONE_FORMAT) if records.any?
  end

  def force_resync?
    resync_token_modified?
  end

  def records_to_sync
    Medication.all
  end
end
