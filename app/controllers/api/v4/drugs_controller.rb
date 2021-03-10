class Api::V4::DrugsController < Api::V4::SyncController
  skip_before_action :current_user_present?, only: [:sync_to_user]
  skip_before_action :validate_sync_approval_status_allowed, only: [:sync_to_user]
  skip_before_action :authenticate, only: [:sync_to_user]
  skip_before_action :validate_facility, only: [:sync_to_user]
  skip_before_action :validate_current_facility_belongs_to_users_facility_group, only: [:sync_to_user]

  def sync_to_user
    __sync_to_user__("drugs")
  end

  private

  def current_facility_records
    []
  end

  def other_facility_records
    time(__method__) do
      Drug.all
    end
  end

  def disable_audit_logs?
    true
  end

  def transform_to_response(drug)
    Api::V4::DrugTransformer.to_response(drug)
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
