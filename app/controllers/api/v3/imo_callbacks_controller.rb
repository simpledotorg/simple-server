class Api::V3::ImoCallbacksController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate_request

  def subscribe
    if permitted_params[:event] == "accept_invite"
      patient = Patient.find(permitted_params[:patient_id])
      patient.imo_authorization.status_subscribed!
    else
      # raise
    end
  end

  private

  def permitted_params
    params.permit(:patient_id, :event)
  end

  def authenticate_request
    authenticate_or_request_with_http_basic do |username, password|
      username == ENV["IMO_CALLBACK_USERNAME"] && password == ENV["IMO_CALLBACK_PASSWORD"]
    end
  end
end