class Api::V1::FacilitiesController < Api::V2::FacilitiesController
  include Api::V1::ApiControllerOverrides
  include Api::V1::SyncControllerOverrides

  def find_records_to_sync(since, limit)
    Facility.updated_on_server_since(since, limit)
      .where.not(facility_group: nil)
  end
end
