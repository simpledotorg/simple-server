class Messaging::Twilio::Api
  include Rails.application.routes.url_helpers
  include Memery

  class Error < StandardError
    # https://www.twilio.com/docs/api/errors
    ERROR_CODE_REASONS = {21211 => :invalid_phone_number,
                          21614 => :invalid_phone_number}

    attr_reader :message, :reason

    def initialize(message, error_code)
      @message = "Error while calling Twilio API: #{message}"
      @reason = ERROR_CODE_REASONS[error_code]
    end
  end

  def callback_url
    api_v3_twilio_sms_delivery_url(
    host: ENV.fetch("SIMPLE_SERVER_HOST"),
    protocol: ENV.fetch("SIMPLE_SERVER_HOST_PROTOCOL")
  )
  end

  def send_message(recipient_number:, message:)
    client.messages.create(
      from: sender_number,
      to: recipient_number,
      status_callback: callback_url,
      body: message
    )
  rescue Twilio::REST::RestError => exception
    raise Error.new(exception.message, exception.code)
  end

  # To by supplied by the individual channel.
  def sender_number
    nil
  end

  def twilio_account_sid
    nil
  end

  def twilio_auth_token
    nil
  end

  def test_mode?
    !(ENV["TWILIO_PRODUCTION_OVERRIDE"] || SimpleServer.env.production?)
  end

  memoize def twilio_account_sid
    return ENV.fetch("TWILIO_TEST_ACCOUNT_SID") if test_mode?
    ENV.fetch("TWILIO_ACCOUNT_SID")
  end

  memoize def twilio_auth_token
    return ENV.fetch("TWILIO_TEST_ACCOUNT_SID") if test_mode?
    ENV.fetch("TWILIO_AUTH_TOKEN")
  end

  private

  memoize def client
    Twilio::REST::Client.new(twilio_account_sid, twilio_auth_token)
  end

  def track(context)
    communication_type = context[:communication_type]
    metrics.increment("#{communication_type}.attempts")
    data = context.merge(msg: "sending #{communication_type} message")
    logger.info data
  end
end
