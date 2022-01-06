# frozen_string_literal: true

class Api::V3::ImoCallbacksController < ApplicationController
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
      Statsd.instance.increment("imo.callback.unknown_error")
      raise ImoCallbackError.new("unexpected Imo invitation event: #{params[:event]}")
    end

    patient = Patient.find(params[:patient_id])
    unless patient.imo_authorization
      Statsd.instance.increment("imo.callback.missing_imo_auth_error")
      raise ImoCallbackError.new("patient #{patient.id} does not have an ImoAuthorization")
    end
    Statsd.instance.increment("imo.callback.subscribed")
    patient.imo_authorization.status_subscribed!
    head :ok
  end

  def read_receipt
    unless params[:event] == "read_receipt"
      raise ImoCallbackError.new("unexpected Imo receipt event: #{params[:event]}")
    end

    detail = ImoDeliveryDetail.find_by!(post_id: params[:post_id])

    if detail.read?
      # just in case any errors in imo's system result in repeated callbacks
      logger.error(class: self.class.name, msg: "detail #{detail.id} already marked read")
    else
      detail.update!(result: "read", read_at: Time.current)
    end

    head :ok
  end
end
