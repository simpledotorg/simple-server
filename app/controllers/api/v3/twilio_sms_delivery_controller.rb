# frozen_string_literal: true

class Api::V3::TwilioSmsDeliveryController < ApplicationController
  before_action :validate_request
  skip_before_action :verify_authenticity_token

  def create
    twilio_message = TwilioSmsDeliveryDetail.includes(communication: :notification).find_by(session_id: message_session_id)
    return head :not_found unless twilio_message

    twilio_message.update(update_params)

    communication_type = twilio_message.communication.communication_type
    event = [communication_type, twilio_message.result].join(".")
    metrics.increment(event)

    notification = twilio_message.communication.notification

    if twilio_message.unsuccessful? && notification&.next_communication_type
      notification.status_scheduled!
      AppointmentNotification::Worker.perform_at(Communication.next_messaging_time, notification.id)
    end

    head :ok
  end

  private

  def metrics
    @metrics ||= Metrics.with_prefix("twilio_callback")
  end

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
