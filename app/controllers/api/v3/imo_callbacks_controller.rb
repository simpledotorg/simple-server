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
    unless params[:event] == "accept_invite"
      raise ImoCallbackError.new("unexcepted Imo invitation event: #{params[:event]}")
    end

    patient = Patient.find(params[:patient_id])
    unless patient.imo_authorization
      raise ImoCallbackError.new("patient #{patient.id} does not have an ImoAuthorization")
    end
    patient.imo_authorization.status_subscribed!
    head :ok
  end

  def read_receipt
    detail = ImoDeliveryDetail.find_by!(post_id: params[:post_id])
    unless detail
      raise ActiveRecord::RecordNotFound, "no ImoDeliveryDetail found for communication #{communication.id}"
    end
    if detail.result == "read"
      # just in case any errors in imo's system result in repeated callbacks
      logger.error "detail #{detail.id} already marked read"
    else
      detail.update!(result: "read", read_at: Time.current)
    end

    head :ok
  end
end
