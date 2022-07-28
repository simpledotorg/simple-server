class Messaging::Twilio::Error < Messaging::Error
  # https://www.twilio.com/docs/api/errors
  ERROR_CODE_REASONS = {21211 => :invalid_phone_number,
                        21614 => :invalid_phone_number}

  def initialize(message, error_code)
    @message = "Error while calling Twilio API: #{message}"
    @reason = ERROR_CODE_REASONS[error_code]
  end

  attr_reader :message, :reason
end
