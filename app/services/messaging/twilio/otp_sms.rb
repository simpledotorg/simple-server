class Messaging::Twilio::OtpSms < Messaging::Twilio::Api
  def initialize
    TestSms.new unless ENV["TWILIO_PRODUCTION_OVERRIDE"] || SimpleServer.env.production?
  end

  memoize def twilio_account_sid
    ENV.fetch("TWILIO_ACCOUNT_SID")
  end

  memoize def twilio_auth_token
    ENV.fetch("TWILIO_AUTH_TOKEN")
  end

  memoize def sender_number
    ENV.fetch("TWILIO_PHONE_NUMBER")
  end
end
