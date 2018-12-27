class Api::Current::ProtocolsController < Api::Current::SyncController
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

  def transform_to_response(protocol)
    protocol.as_json(include: :protocol_drugs)
  end

  def response_process_token
    { other_facilities_processed_since: processed_until(other_facility_records) || other_facilities_processed_since }
  end
end
