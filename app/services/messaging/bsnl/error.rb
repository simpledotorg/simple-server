class Messaging::Bsnl::Error < Messaging::Error
  ERROR_CODE_REASONS = {/Invalid Mobile Number/ => :invalid_phone_number}

  def initialize(message)
    @message = message
    @reason = error_reason(message)
  end

  def error_reason(message)
    known_error_message = ERROR_CODE_REASONS.keys.find { |error_message| error_message.match(message).present? }
    ERROR_CODE_REASONS[known_error_message] if known_error_message
  end
end
