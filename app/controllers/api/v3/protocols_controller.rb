class Api::V3::ProtocolsController < Api::V3::SyncController
  include Api::V3::PublicApi

  def sync_to_user
    __sync_to_user__("protocols")
  end

  private

  def records_to_sync
    Protocol
      .with_discarded
      .updated_on_server_since(processed_since, limit)
  end

  def disable_audit_logs?
    true
  end

  def transform_to_response(protocol)
    protocol.as_json
  end

  def response_process_token
    {
      processed_since: processed_until(records_to_sync) || processed_since,
      resync_token: resync_token
    }
  end

  def force_resync?
    resync_token_modified?
  end
end
