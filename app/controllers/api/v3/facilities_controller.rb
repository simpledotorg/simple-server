class Api::V3::FacilitiesController < Api::V3::SyncController
  skip_before_action :current_user_present?, only: [:sync_to_user]
  skip_before_action :validate_sync_approval_status_allowed, only: [:sync_to_user]
  skip_before_action :authenticate, only: [:sync_to_user]
  skip_before_action :validate_facility, only: [:sync_to_user]
  skip_before_action :validate_current_facility_belongs_to_users_facility_group, only: [:sync_to_user]

  def sync_to_user
    __sync_to_user__("facilities")
  end

  private

  def current_facility_records
    []
  end

  def other_facility_records
    time(__method__) do
      Facility
        .with_discarded
        .updated_on_server_since(other_facilities_processed_since, limit)
    end
  end

  def disable_audit_logs?
    true
  end

  def transform_to_response(facility)
    Api::V3::FacilityTransformer
      .to_response(facility)
      .merge(sync_region_id: sync_region_id(facility))
  end

  def response_process_token
    {
      other_facilities_processed_since: processed_until(other_facility_records) || other_facilities_processed_since,
      resync_token: resync_token
    }
  end

  def force_resync?
    resync_token_modified?
  end

  def records_to_sync
    time(__method__) do
      other_facility_records
        .with_block_region_id
        .includes(:facility_group)
        .where.not(facility_group: nil)
    end
  end

  private

  # Memoize this call so that we don't end up making thousands of calls to check user for each facility
  def block_level_sync?
    return @block_level_sync_enabled if defined? @block_level_sync_enabled
    @block_level_sync_enabled = current_user&.block_level_sync?
  end

  def sync_region_id(facility)
    if block_level_sync?
      facility.block_region_id
    else
      facility.facility_group_id
    end
  end
end
