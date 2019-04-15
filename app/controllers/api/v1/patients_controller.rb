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

  def patients_params
    permitted_address_params = %i[id street_address village_or_colony district state country pin created_at updated_at]
    permitted_phone_number_params = %i[id number phone_type active created_at updated_at]

    patient_attributes = params.require(:patients)
    patient_attributes.map do |single_patient_params|
      single_patient_params.permit(
        :id,
        :full_name,
        :age,
        :age_updated_at,
        :gender,
        :status,
        :date_of_birth,
        :created_at,
        :updated_at,
        phone_numbers: [permitted_phone_number_params],
        address: permitted_address_params
      )
    end
  end
end
