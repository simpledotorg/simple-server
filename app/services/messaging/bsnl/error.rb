class Messaging::Bsnl::Error < Messaging::Error
  ERROR_CODE_REASONS = {/Invalid Mobile Number/ => :invalid_phone_number}

  def initialize(message)
    @message = "Error while calling BSNL API: #{message}"
    @reason = error_reason(message)
  end

  def error_reason(message)
    known_error_message = ERROR_CODE_REASONS.keys.select do |e|
      e.match(message).present?
    end.first

    ERROR_CODE_REASONS[known_error_message]
  end
end
