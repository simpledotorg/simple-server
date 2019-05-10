class Api::V2::CommunicationsController < Api::Current::CommunicationsController
  def communications_params
    params.require(:communications).map do |communication_params|
      communication_params.permit(
        :id,
        :appointment_id,
        :user_id,
        :communication_type,
        :communication_result,
        :created_at,
        :updated_at)
    end
  end
end
