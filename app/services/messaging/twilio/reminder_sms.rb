class Messaging::Twilio::ReminderSms < Messaging::Twilio::Api
  TWILIO_TEST_SMS_NUMBER = "+15005550006"

  def communication_type
    Communication.communication_types[:sms]
  end

  def sender_number
    if test_mode?
      TWILIO_TEST_SMS_NUMBER
    else
      senders.sample
    end
  end

  private

  def senders
    ENV.fetch("TWILIO_APPOINTMENT_REMINDER_NUMBERS", "").split(",").map(&:strip)
  end
end
