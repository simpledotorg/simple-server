class Api::V2::PatientsController < Api::Current::PatientsController
  private

  def merge_if_valid(single_patient_params)
    validator = Api::V2::PatientPayloadValidator.new(single_patient_params)
    logger.debug "Patient had errors: #{validator.errors_hash}" if validator.invalid?
    if validator.invalid?
      NewRelic::Agent.increment_metric('Merge/Patient/schema_invalid')
      { errors_hash: validator.errors_hash }
    else
      single_patient_params_with_recorded_at = set_default_recorded_at(single_patient_params)
      patients_params_with_metadata = single_patient_params_with_recorded_at.merge(metadata: metadata)
      patient = MergePatientService.new(
        Api::V2::PatientTransformer.from_nested_request(patients_params_with_metadata)
      ).merge
      { record: patient }
    end
  end

  def set_default_recorded_at(patient_params)
    patient = Patient.find_by(id: patient_params['id'])

    if patient.present?
      earliest_blood_pressure = patient.blood_pressures.order(device_created_at: :asc).first
      if earliest_blood_pressure.present?
        patient_params['recorded_at'] = [patient.device_created_at, earliest_blood_pressure.device_created_at].min
      else
        patient_params['recorded_at'] = patient.device_created_at
      end
    else
      patient_params['recorded_at'] = patient_params['created_at']
    end

    patient_params
  end

  def transform_to_response(patient)
    Api::V2::PatientTransformer.to_nested_response(patient)
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
