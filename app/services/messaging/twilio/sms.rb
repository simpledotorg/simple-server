class Messaging::Twilio::Sms < Messaging::Twilio::Api
  TWILIO_TEST_SMS_NUMBER = "+15005550006"

  memoize def sender_number
    return TWILIO_TEST_SMS_NUMBER if test_mode?
    senders.sample
  end

  private

  def senders
    ENV.fetch("TWILIO_APPOINTMENT_REMINDER_NUMBERS", "").split(",").map(&:strip)
  end
end
