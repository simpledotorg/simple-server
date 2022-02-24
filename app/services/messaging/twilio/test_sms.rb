class Messaging::Twilio::TestSms < Messaging::Twilio::Api
  memoize def twilio_account_sid
    ENV.fetch("TWILIO_TEST_ACCOUNT_SID")
  end

  memoize def twilio_auth_token
    ENV.fetch("TWILIO_TEST_AUTH_TOKEN")
  end

  memoize def sender_number
    TWILIO_TEST_SMS_NUMBER
  end
end
