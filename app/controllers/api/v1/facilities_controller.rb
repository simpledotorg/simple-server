class Api::V1::FacilitiesController < Api::V1::SyncController
  def sync_to_user
    __sync_to_user__('facilities')
  end

  private

  def find_records_to_sync(since, limit)
    Facility.updated_on_server_since(since, limit)
  end

  def transform_to_response(facility)
    facility.as_json
  end
end
