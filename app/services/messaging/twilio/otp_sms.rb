class Messaging::Twilio::OtpSms < Messaging::Twilio::Api
  # This number comes from https://www.twilio.com/docs/iam/test-credentials#test-sms-messages-parameters-From
  TWILIO_TEST_SMS_NUMBER = "+15005550006"

  def self.communication_type
    Communication.communication_types[:sms]
  end

  def sender_number
    if test_mode?
      TWILIO_TEST_SMS_NUMBER
    else
      ENV.fetch("TWILIO_PHONE_NUMBER")
    end
  end
end
