class Messaging::AlphaSms::Error < Messaging::Error
  ERROR_CODE_REASONS = {400 => :invalid_request,
                        403 => :invalid_request,
                        404 => :invalid_request,
                        405 => :invalid_request,
                        409 => :server_error,
                        410 => :account_expired,
                        411 => :account_expired,
                        413 => :invalid_sender_id,
                        414 => :invalid_message,
                        416 => :invalid_phone_number,
                        417 => :balance_error}

    def initialize(message, error_code=nil)
    @message = "Error while calling Alpha SMS API: #{message}"
    @reason = ERROR_CODE_REASONS[error_code]
  end

  attr_reader :message, :reason
end
