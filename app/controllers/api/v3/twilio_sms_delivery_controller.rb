class Api::V3::TwilioSmsDeliveryController < ApplicationController
  before_action :validate_request
  skip_before_action :verify_authenticity_token

  def create
    TwilioSmsDeliveryDetail.where(session_id: message_session_id).first.update(update_params)
    head :ok
  end

  private

  def update_params
    details = {result: delivery_status}
    details[:delivered_on] = DateTime.current if delivery_status == TwilioSmsDeliveryDetail.results[:delivered]

    details
  end

  def message_session_id
    params["MessageSid"] || params["SmsSid"]
  end

  def delivery_status
    params["SmsStatus"] || params["MessageStatus"] || TwilioSmsDeliveryDetail.results[:unknown]
  end

  def validate_request
    validator = Twilio::Security::RequestValidator.new(ENV.fetch("TWILIO_AUTH_TOKEN"))
    unless validator.validate(request.original_url,
      request.request_parameters,
      request.headers["X-Twilio-Signature"])
      head :forbidden
    end
  end
end
