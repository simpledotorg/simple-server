class Api::V1::PatientsController < ApplicationController

  def merge_address(address_params)
    address = Address.new(address_params)
    MergeRecord.merge_by_id(address)
  end

  def merge_phone_number(phone_number_params)
    phone_number = PhoneNumber.new(phone_number_params)
    MergeRecord.merge_by_id(phone_number)
  end

  def merge_phone_numbers(single_patient_params)
    single_patient_params[:phone_numbers].to_a.map do |phone_number_params|
      merge_phone_number phone_number_params
    end
  end

  def merge_patient(single_patient_params)
    patient = Patient.new(single_patient_params.except(:address, :phone_numbers))
    patient.address = merge_address(single_patient_params[:address]) if single_patient_params[:address].present?
    patient.phone_numbers = merge_phone_numbers(single_patient_params)
    MergeRecord.merge_by_id(patient)
  end

  def sync_from_user
    invalid_patient_ids = []
    patient_params.each do |single_patient_params|
      patient = merge_patient single_patient_params
      invalid_patient_ids << single_patient_params[:id] unless patient
    end

    response = invalid_patient_ids.empty? ? nil : { errors: invalid_patient_ids }
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
