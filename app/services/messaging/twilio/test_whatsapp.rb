class Messaging::Twilio::TestWhatsapp < Messaging::Twilio::Api
  TWILIO_TEST_WHATSAPP_NUMBER = "+14155238886"

  memoize def twilio_account_sid
    ENV.fetch("TWILIO_TEST_ACCOUNT_SID")
  end

  memoize def twilio_auth_token
    ENV.fetch("TWILIO_TEST_AUTH_TOKEN")
  end

  memoize def sender_number
    "whatsapp:" + TWILIO_TEST_WHATSAPP_NUMBER
  end

  def send(recipient_number, message)
    super("whatsapp:" + recipient_number, message)
  end
end
