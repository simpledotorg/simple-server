class Api::V3::TwilioSmsDeliveryController < ApplicationController
  before_action :validate_request
  skip_before_action :verify_authenticity_token

  def create
    twilio_message = TwilioSmsDeliveryDetail.includes(:communication).find_by(session_id: message_session_id)
    return head :not_found unless twilio_message

    twilio_message.update(update_params)
    head :ok
  end

  private

  def update_params
    details = {result: message_status}
    details[:delivered_on] = DateTime.current if message_status == TwilioSmsDeliveryDetail.results[:delivered]
    details[:read_at] = DateTime.current if message_status == TwilioSmsDeliveryDetail.results[:read]

    details
  end

  def message_session_id
    params["MessageSid"] || params["SmsSid"]
  end

  def message_status
    params["MessageStatus"] || params["SmsStatus"] || TwilioSmsDeliveryDetail.results[:unknown]
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
