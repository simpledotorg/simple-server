class Api::V4::StatesController < APIController
  include Api::V3::PublicApi

  def sync_to_user
    state_names = Region.facility_regions
      .joins("inner join regions states ON states.path @> regions.path and states.region_type = 'state'")
      .distinct("states.name")
      .pluck("states.name")

    render json: state_names
  end
end
