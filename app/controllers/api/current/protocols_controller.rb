class Api::Current::ProtocolsController < Api::Current::SyncController
  def sync_to_user
    __sync_to_user__('protocols')
  end

  def find_records_to_sync(since, limit)
    super(since, limit).includes(:protocol_drugs)
  end

  private

  def transform_to_response(protocol)
    protocol.as_json(include: :protocol_drugs)
  end
end
