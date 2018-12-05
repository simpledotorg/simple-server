class Api::V1::PrescriptionDrugsController < Api::Current::PrescriptionDrugsController
  include Api::V1::ApiControllerOverrides
  include Api::V1::SyncControllerOverrides

  def find_records_to_sync(since, limit)
    PrescriptionDrug.where(facility: current_user.facilities_in_group)
      .updated_on_server_since(since, limit)
  end
end
