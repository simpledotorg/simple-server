# frozen_string_literal: true

class Api::V3::FacilitiesController < Api::V3::SyncController
  include Api::V3::PublicApi
  include Memery

  def sync_to_user
    __sync_to_user__("facilities")
  end

  private

  def current_facility_records
    []
  end

  def other_facility_records
    Facility
      .with_discarded
      .updated_on_server_since(other_facilities_processed_since, limit)
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
    other_facility_records
      .with_block_region_id
      .includes(:facility_group)
      .where.not(facility_group: nil)
  end

  memoize def district_level_sync?
    current_user&.district_level_sync?
  end

  def sync_region_id(facility)
    if district_level_sync?
      facility.facility_group_id
    else
      facility.block_region_id
    end
  end
end
