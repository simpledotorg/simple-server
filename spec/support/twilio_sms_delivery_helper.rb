# frozen_string_literal: true

module TwilioSMSDeliveryHelper
  def set_twilio_signature_header(url, params)
    request.headers["X-Twilio-Signature"] =
      Twilio::Security::RequestValidator.new(ENV.fetch("TWILIO_AUTH_TOKEN")).build_signature_for(url, params)
  end
end
