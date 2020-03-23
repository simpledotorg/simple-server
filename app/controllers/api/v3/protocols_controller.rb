class Api::V3::ProtocolsController < Api::V3::SyncController
  skip_before_action :current_user_present?, only: [:sync_to_user]
  skip_before_action :validate_sync_approval_status_allowed, only: [:sync_to_user]
  skip_before_action :authenticate, only: [:sync_to_user]
  skip_before_action :validate_facility, only: [:sync_to_user]
  skip_before_action :validate_current_facility_belongs_to_users_facility_group, only: [:sync_to_user]
  
  def sync_to_user
    __sync_to_user__('protocols')
  end

  def find_records_to_sync(since, limit)
    super(since, limit).includes(:protocol_drugs)
  end

  private

  def disable_audit_logs?
    true
  end

  def transform_to_response(protocol)
    protocol.as_json(include: :protocol_drugs)
  end

  def response_process_token
    { other_facilities_processed_since: processed_until(other_facility_records) || other_facilities_processed_since, 
      resync_token: resync_token }
  end
end
