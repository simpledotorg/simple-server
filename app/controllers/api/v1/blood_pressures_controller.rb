class Api::V1::BloodPressuresController < Api::Current::BloodPressuresController
  include Api::V1::ApiControllerOverrides
  include Api::V1::SyncControllerOverrides

  def find_records_to_sync(since, limit)
    BloodPressure.where(facility: current_user.facilities_in_group)
      .updated_on_server_since(since, limit)
  end
end
