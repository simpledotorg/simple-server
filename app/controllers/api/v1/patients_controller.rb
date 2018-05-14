class Api::V1::PatientsController < ApplicationController

  def sync_from_user
    validated_patients = patient_params.map do |single_patient_params|
      Patient.new_patient_from_nested_params single_patient_params
    end

    MergeRecord.bulk_merge_on_id(validated_patients.select(&:valid?))
    invalid_records = validated_patients.reject(&:valid?)

    response = invalid_records.empty? ? nil : { errors: invalid_records.map(&:errors) }
    render json: response, status: :ok
  end

  private

  def patient_params
    permitted_address_params      = %i[id street_address colony village district state country pin created_at updated_at]
    permitted_phone_number_params = %i[id number type active created_at updated_at]
    params.require(:patients).map do |single_patient_params|
      single_patient_params.permit(
        :id,
        :full_name,
        :age_when_created,
        :gender,
        :status,
        :date_of_birth,
        :created_at,
        :updated_at,
        phone_numbers: [permitted_phone_number_params],
        address:       permitted_address_params)
    end
  end
end
