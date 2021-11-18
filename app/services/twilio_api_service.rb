# See https://www.twilio.com/docs/iam/test-credentials#test-sms-messages-parameters-From
# https://www.twilio.com/docs/whatsapp/sandbox#what-is-the-twilio-sandbox-for-whatsapp
# Twilio does not offer a true sandbox environment that separates logs from production.
# Instead, they build mocked TO/FROM numbers into the gem. So by using different TO/FROM
# numbers you can force different response types. To have a fully functional sandbox environment
# with its own logging, you would need to set up a different Twilio account and use those credentials.
# ERROR HANDLING: this class is primarily used by background jobs. We raise an error on
# twilio errors without error codes because network errors do not have error codes
# and we want to force a retry on network errors. If a twilio error has a code,
# we log the error but do not want to retry because the errors listed in their docs
# are idempotent and retries would yield the same errors.

class TwilioApiService
  attr_accessor :communication_type
  attr_reader :client
  attr_reader :metrics
  attr_reader :twilio_sender_sms_number
  attr_reader :twilio_sender_whatsapp_number

  TWILIO_TEST_SMS_NUMBER = "+15005550006"
  TWILIO_TEST_WHATSAPP_NUMBER = "+14155238886"

  delegate :logger, to: Rails

  class Error < StandardError
    STATUS_CODE_REASONS = {400 => :invalid_phone_number}

    attr_reader :message, :reason

    def initialize(message, status_code)
      @message = "Error while calling Twilio API: #{message}"
      @reason = STATUS_CODE_REASONS[status_code]
    end
  end

  def logger
    @logger ||= Notification.logger(class: self.class.name)
  end

  def initialize(sms_sender: nil)
    @test_mode = if ENV["TWILIO_PRODUCTION_OVERRIDE"]
      false
    else
      !SimpleServer.env.production?
    end

    @twilio_account_sid = ENV.fetch("TWILIO_ACCOUNT_SID")
    @twilio_auth_token = ENV.fetch("TWILIO_AUTH_TOKEN")

    @twilio_test_account_sid = ENV.fetch("TWILIO_TEST_ACCOUNT_SID")
    @twilio_test_auth_token = ENV.fetch("TWILIO_TEST_AUTH_TOKEN")

    @twilio_sender_sms_number = if test_mode?
      TWILIO_TEST_SMS_NUMBER
    elsif sms_sender
      sms_sender
    else
      ENV.fetch("TWILIO_PHONE_NUMBER")
    end
    @twilio_sender_whatsapp_number = test_mode? ? TWILIO_TEST_WHATSAPP_NUMBER : ENV.fetch("TWILIO_PHONE_NUMBER")

    @client = if @test_mode
      test_client
    else
      prod_client
    end
    @metrics = Metrics.with_object(self)
  end

  def test_mode?
    @test_mode
  end

  def prod_client
    @prod_client ||= Twilio::REST::Client.new(@twilio_account_sid, @twilio_auth_token)
  end

  def test_client
    @test_client ||= Twilio::REST::Client.new(@twilio_test_account_sid, @twilio_test_auth_token)
  end

  def send_sms(recipient_number:, message:, callback_url: nil, context: {})
    track(context)
    sender_number = twilio_sender_sms_number

    send_twilio_message(sender_number, recipient_number, message, callback_url, context)
  end

  def send_whatsapp(recipient_number:, message:, callback_url: nil, context: {})
    track(context)
    sender_number = "whatsapp:" + twilio_sender_whatsapp_number
    recipient_number = "whatsapp:" + recipient_number

    send_twilio_message(sender_number, recipient_number, message, callback_url, context)
  end

  private

  def track(context)
    communication_type = context[:communication_type]
    metrics.increment("#{communication_type}.attempts")
    data = context.merge(msg: "sending #{communication_type} message")
    logger.info data
  end

  def send_twilio_message(sender_number, recipient_number, message, callback_url, context)
    Sentry.set_tags(context)
    response = client.messages.create(
      from: sender_number,
      to: recipient_number,
      status_callback: callback_url,
      body: message
    )
    metrics.increment("#{communication_type}.sent")
    response
  rescue Twilio::REST::RestError => exception
    metrics.increment("#{communication_type}.errors")
    raise Error.new(exception.message, exception.status_code)
  end
end
