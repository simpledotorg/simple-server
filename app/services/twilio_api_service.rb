class TwilioApiService
  attr_reader :client
  attr_reader :response
  attr_reader :twilio_sender_sms_number
  attr_reader :twilio_sender_whatsapp_number

  # See https://www.twilio.com/docs/iam/test-credentials#test-sms-messages-parameters-From
  # https://www.twilio.com/docs/whatsapp/sandbox#what-is-the-twilio-sandbox-for-whatsapp
  TWILIO_TEST_SMS_NUMBER = "+15005550006"
  TWILIO_TEST_WHATSAPP_NUMBER = "+14155238886"

  class Error < StandardError
    attr_reader :exception_message, :context
    def initialize(message, exception_message:, context:)
      super(message)
      @exception_message = exception_message
      @context = context
    end
  end

  def initialize(sms_sender: nil)
    @test_mode = !SimpleServer.env.production?

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

  def send_sms(recipient_number:, message:, callback_url:  nil, context: {})
    sender_number = twilio_sender_sms_number
    recipient_number = parse_phone_number(recipient_number)

    send_twilio_message(sender_number, recipient_number, message, callback_url, context)
  end

  def send_whatsapp(recipient_number:, message:, callback_url:  nil, context: {})
    sender_number = "whatsapp:" + twilio_sender_whatsapp_number
    recipient_number = "whatsapp:" + parse_phone_number(recipient_number)

    send_twilio_message(sender_number, recipient_number, message, callback_url, context)
  end

  def parse_phone_number(number)
    parsed_number = Phonelib.parse(number, Rails.application.config.country[:abbreviation]).raw_national
    default_country_code + parsed_number
  end

  private

  def default_country_code
    Rails.application.config.country[:sms_country_code]
  end

  def send_twilio_message(sender_number, recipient_number, message, callback_url, context)
    client.messages.create(
      from: sender_number,
      to: recipient_number,
      status_callback: callback_url,
      body: message
    )
  rescue Twilio::REST::TwilioError => exception
    # see the link above for a list of codes; the else case happens on network failures
    if exception.respond_to?(:code)
      report_error(exception, context)
      nil
    else
      raise Error.new("Error while calling Twilio API", exception_message: exception.to_s, context: context)
    end
  end

  def report_error(e, context)
    Sentry.capture_message(
      "Error while processing notification",
      extra: {
        exception: e.to_s,
        context: context.to_json
      },
      tags: {
        type: "twilio-api-service"
      }
    )
  end
end
