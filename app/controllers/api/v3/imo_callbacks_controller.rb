class Api::V3::ImoCallbacksController < ApplicationController
  http_basic_authenticate_with name: ENV["IMO_CALLBACK_USERNAME"], password: ENV["IMO_CALLBACK_PASSWORD"]
  skip_before_action :verify_authenticity_token

  class ImoCallbackError < StandardError; end
  rescue_from ImoCallbackError do
    head :bad_request
  end

  rescue_from ActiveRecord::RecordNotFound do
    head :not_found
  end

  def subscribe
    unless permitted_params[:event] == "accept_invite"
      raise ImoCallbackError.new("unexcepted Imo invitation event: #{permitted_params[:event]}")
    end

    patient = Patient.find(permitted_params[:patient_id])
    unless patient.imo_authorization
      raise ImoCallbackError.new("patient #{patient.id} does not have an ImoAuthorization")
    end
    patient.imo_authorization.status_subscribed!
    head :ok
  end

  def read_receipt
    notification = Notification.find(params[:notification_id])
    communication = notification.communications.find_by!(communication_type: "imo")

    # this should raise
    detail = communication.detailable
    detail.update!(result: "read")

    head :ok
  end

  private

  def permitted_params
    params.permit(:patient_id, :event)
  end
end
