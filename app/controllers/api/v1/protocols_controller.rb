class Api::V1::ProtocolsController < Api::V2::ProtocolsController
  include Api::V1::ApiControllerOverrides
  include Api::V1::SyncControllerOverrides

  def find_records_to_sync(since, limit)
    Protocol.includes(:protocol_drugs).updated_on_server_since(since, limit)
  end
end
