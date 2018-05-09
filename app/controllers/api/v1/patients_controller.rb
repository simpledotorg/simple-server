class Api::V1::PatientsController < ApplicationController
  def sync_from_user
    MergeRecord.bulk_merge_on_id(Patient, patient_params)
    render json: nil, status: :ok
  end

  def sync_to_user
    # Placeholder, for symmetry
    nil
  end

  private

  def patient_params
    params.require(:patients).map do |single_patient_params|
      single_patient_params.permit(:id, :full_name, :age_when_created, :gender, :created_at, :updated_at)
    end
  end
end
