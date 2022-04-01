class Messaging::Twilio::Api < Messaging::Channel
  include Rails.application.routes.url_helpers
  include Memery

  def fetch_message(sid)
    client.messages(sid).fetch
  end

  def send_message(recipient_number:, message:, &with_communication_do)
    track_metrics do
      create_communication(
        recipient_number,
        send_twilio_message(recipient_number, message),
        &with_communication_do
      )
    rescue Twilio::REST::RestError => exception
      raise Messaging::Twilio::Error.new(exception.message, exception.code)
    end
  end

  def sender_number
    raise NotImplementedError
  end

  private

  def create_communication(recipient_number, response, &with_communication_do)
    ActiveRecord::Base.transaction do
      TwilioSmsDeliveryDetail.create_with_communication!(
        callee_phone_number: recipient_number,
        communication_type: self.class.communication_type,
        session_id: response.sid,
        result: response.status
      ).tap do |communication|
        with_communication_do&.call(communication)
      end
    end
  end

  def send_twilio_message(recipient_number, message)
    client.messages.create(
      from: sender_number,
      to: recipient_number,
      status_callback: callback_url,
      body: message
    )
  end

  memoize def client
    credentials = test_mode? ? test_credentials : production_credentials
    Twilio::REST::Client.new(credentials[:account_sid], credentials[:auth_token])
  end

  def test_mode?
    !(ENV["TWILIO_PRODUCTION_OVERRIDE"] || SimpleServer.env.production?)
  end

  def test_credentials
    {
      account_sid: ENV.fetch("TWILIO_TEST_ACCOUNT_SID"),
      auth_token: ENV.fetch("TWILIO_TEST_AUTH_TOKEN")
    }
  end

  def production_credentials
    {
      account_sid: ENV.fetch("TWILIO_ACCOUNT_SID"),
      auth_token: ENV.fetch("TWILIO_AUTH_TOKEN")
    }
  end

  def callback_url
    api_v3_twilio_sms_delivery_url(
      host: ENV.fetch("SIMPLE_SERVER_HOST"),
      protocol: ENV.fetch("SIMPLE_SERVER_HOST_PROTOCOL")
    )
  end
end
