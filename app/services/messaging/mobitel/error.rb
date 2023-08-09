class Messaging::Mobitel::Error < Messaging::Error
  API_RESPONSE_CODE = {
    200 => :ok,
    151 => :invalid_session,
    152 => :session_in_use,
    155 => :service_halted,
    156 => :other_networking_messaging_disabled,
    157 => :idd_messages_disabled,
    159 => :failed_credit_check,
    160 => :no_message_found,
    161 => :message_exceeding_160_characters,
    162 => :invalid_message_type_found,
    164 => :invalid_group,
    165 => :no_recipients_found,
    166 => :recipient_list_exceeding_allowed_limit,
    167 => :invalid_long_number,
    168 => :invalid_short_code,
    169 => :invalid_alias,
    170 => :black_listed_numbers_in_number_list,
    171 => :non_white_listed_numbers_in_number_list
  }

  def initialize(message, error_code = nil)
    @message = "Error while calling Mobitel API: #{message}"
    @reason = API_RESPONSE_CODE[error_code]
  end

  attr_reader :message, :reason
end
