class Api::V3::FacilitiesController < Api::V3::SyncController
  include Api::V3::PublicApi

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
      .merge(sync_region_id: facility.block_region_id)
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
end
