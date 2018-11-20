class Api::V1::PatientsController < Api::Current::PatientsController
  include Api::V1::Overrides

  def metadata
    { registration_user_id: current_user.id,
      registration_facility_id: nil }
  end
end
