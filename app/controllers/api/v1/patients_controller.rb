class Api::V1::PatientsController < Api::Current::PatientsController
  include Api::V1::ApiControllerOverrides
  include Api::V1::SyncControllerOverrides

  def metadata
    { registration_user_id: current_user.id,
      registration_facility_id: nil }
  end

  def find_records_to_sync(since, limit)
    Patient.where(registration_facility: current_user.facilities_in_group)
      .updated_on_server_since(since, limit)
  end
end
