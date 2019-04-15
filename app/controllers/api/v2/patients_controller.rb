class Api::V2::PatientsController < Api::Current::PatientsController
  def transform_to_response(patient)
    Api::V2::PatientTransformer.to_nested_response(patient)
  end
end
