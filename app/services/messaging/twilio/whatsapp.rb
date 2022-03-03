class Messaging::Twilio::Whatsapp < Messaging::Twilio::Api
  # This number comes from https://www.twilio.com/docs/whatsapp/sandbox#what-is-the-twilio-sandbox-for-whatsapp
  TWILIO_TEST_WHATSAPP_NUMBER = "+14155238886"

  def send_message(recipient_number, message)
    super(whatsapp_format(recipient_number), message)
  end

  def communication_type
    Communication.communication_types[:whatsapp]
  end

  def sender_number
    number =
      if test_mode?
        TWILIO_TEST_WHATSAPP_NUMBER
      else
        ENV.fetch("TWILIO_PHONE_NUMBER")
      end

    whatsapp_format(number)
  end

  def whatsapp_format(number)
    "whatsapp:#{number}"
  end
end
