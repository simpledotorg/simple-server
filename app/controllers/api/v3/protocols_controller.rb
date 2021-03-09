class Api::V3::ProtocolsController < Api::V3::SyncController
  skip_before_action :current_user_present?, only: [:sync_to_user]
  skip_before_action :validate_sync_approval_status_allowed, only: [:sync_to_user]
  skip_before_action :authenticate, only: [:sync_to_user]
  skip_before_action :validate_facility, only: [:sync_to_user]
  skip_before_action :validate_current_facility_belongs_to_users_facility_group, only: [:sync_to_user]

  def sync_to_user
    __sync_to_user__("protocols")
  end

  private

  def current_facility_records
    []
  end

  def other_facility_records
    time(__method__) do
      Protocol
        .with_discarded
        .updated_on_server_since(other_facilities_processed_since, limit)
    end
  end

  def disable_audit_logs?
    true
  end

  def transform_to_response(protocol)
    protocol.as_json
  end

  def response_process_token
    {
      other_facilities_processed_since: processed_until(other_facility_records) || other_facilities_processed_since,
      resync_token: resync_token
    }
  end

  def block_level_sync?
    current_user&.block_level_sync?
  end

  def force_resync?
    resync_token_modified?
  end
end
