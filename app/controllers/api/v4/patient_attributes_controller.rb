class Api::V4::PatientAttributesController < Api::V4::SyncController
  def sync_from_user
    __sync_from_user__(patient_attributes_params)
  end

  def sync_to_user
    __sync_to_user__("patient_attributes")
  end

  def metadata
    { user_id: current_user.id }
  end

  private

  def patient_attributes_params
    params.require(:patient_attributes).map do |patient_attribute_params|
      patient_attribute_params.permit(
        :patient_id,
        :height,
        :weight,
        :created_at,
        :updated_at
      )
    end
  end
end
