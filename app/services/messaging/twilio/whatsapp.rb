class Messaging::Twilio::Whatsapp < Messaging::Twilio::Api
  TWILIO_TEST_WHATSAPP_NUMBER = "+14155238886"

  def self.communication_type
    Communication::communication_type[:whatsapp]
  end

  memoize def sender_number
    return whatsapp_number(TWILIO_TEST_WHATSAPP_NUMBER) if test_mode?
    whatsapp_number(ENV.fetch("TWILIO_PHONE_NUMBER"))
  end

  def send(recipient_number, message)
    super(whatsapp_number(recipient_number), message)
  end

  private

  def whatsapp_number(phone_number)
    "whatsapp:" + phone_number
  end
end
