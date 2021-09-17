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
    communication = Communication.find_by!(notification_id: params[:notification_id], communication_type: "imo", detailable_type: "ImoDeliveryDetail")
    detail = communication.detailable
    unless detail
      raise ActiveRecord::RecordNotFound, "no ImoDeliveryDetail found for communication #{communication.id}"
    end
    if detail.result == "read"
      # adding this logging to catch errors in imo's system
      logger.error "detail #{detail.id} already marked read"
    else
      detail.update!(result: "read")
    end

    head :ok
  end

  private

  def permitted_params
    params.permit(:patient_id, :event)
  end
end
