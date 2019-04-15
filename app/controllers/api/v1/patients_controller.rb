class Api::V1::PatientsController < Api::Current::PatientsController
  include Api::V1::ApiControllerOverrides
  include Api::V1::SyncControllerOverrides

  def metadata
    { registration_user_id: current_user.id,
      registration_facility_id: current_facility&.id || current_user.facility.id }
  end

  def transform_to_response(patient)
    Api::V1::PatientTransformer.to_nested_response(patient)
  end
end
