class Api::V3::FacilitiesController < Api::V3::SyncController
  skip_before_action :current_user_present?, only: [:sync_to_user]
  skip_before_action :validate_sync_approval_status_allowed, only: [:sync_to_user]
  skip_before_action :authenticate, only: [:sync_to_user]
  skip_before_action :validate_facility, only: [:sync_to_user]
  skip_before_action :validate_current_facility_belongs_to_users_facility_group, only: [:sync_to_user]

  def sync_to_user
    __sync_to_user__('facilities')
  end

  private

  def disable_audit_logs?
    true
  end

  def transform_to_response(facility)
    Api::V3::FacilityTransformer.to_response(facility)
  end

  def response_process_token
    { other_facilities_processed_since: processed_until(other_facility_records) || other_facilities_processed_since,
      resync_token: resync_token }
  end

  def records_to_sync
    Facility.updated_on_server_since(other_facilities_processed_since, limit).includes(:facility_group)
      .where.not(facility_group: nil)
  end
end
