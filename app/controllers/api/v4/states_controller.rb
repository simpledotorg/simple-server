class Api::V4::StatesController < APIController
  include Api::V3::PublicApi

  def sync_to_user
    render json: Facility.pluck(:state).uniq
  end
end
