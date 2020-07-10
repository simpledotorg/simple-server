class Api::V3::TwilioSmsDeliveryController < ApplicationController
  before_action :validate_request
  skip_before_action :verify_authenticity_token

  def create
    twilio_message = TwilioSmsDeliveryDetail.find_by(session_id: message_session_id)

    twilio_message.update(update_params)
    communication_type = twilio_message.communication.communication_type
    appointment_id = twilio_message.communication.appointment_id

    if communication_type == "missed_visit_whatsapp_reminder" && twilio_message.unsuccessful?
      AppointmentNotification::Worker.perform_at(Communication.next_messaging_time, appointment_id, "missed_visit_sms_reminder")
    end

    head :ok
  end

  private

  def update_params
    details = {result: message_status}
    details[:delivered_on] = DateTime.current if message_status == TwilioSmsDeliveryDetail.results[:delivered]

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
