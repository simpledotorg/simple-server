# frozen_string_literal: true

class Api::V3::ProtocolsController < Api::V3::SyncController
  include Api::V3::PublicApi

  def sync_to_user
    __sync_to_user__("protocols")
  end

  private

  def current_facility_records
    []
  end

  def other_facility_records
    Protocol
      .with_discarded
      .updated_on_server_since(other_facilities_processed_since, limit)
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

  def force_resync?
    resync_token_modified?
  end
end
