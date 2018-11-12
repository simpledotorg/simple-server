class Api::V2::ProtocolsController < Api::SyncController
  def sync_to_user
    __sync_to_user__('protocols')
  end

  private

  def find_records_to_sync(since, limit)
    Protocol.updated_on_server_since(since, limit).includes(:protocol_drugs)
  end

  def transform_to_response(protocol)
    protocol.as_json(include: :protocol_drugs)
  end
end
