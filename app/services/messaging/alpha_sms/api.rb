class Messaging::AlphaSms::Api
  SENDER_ID = ENV["ALPHA_SMS_SENDER_ID"]
  HOST = "api.sms.net.bd"
  URL_PATHS = {
    send_sms: "/sendsms",
    request_report: "/report/request",
    user_balance: "/user/balance"
  }

  def initialize
    if api_key.blank?
      raise Messaging::AlphaSms::Error.new("Missing Alpha SMS credentials")
    end
  end

  def send_sms(recipient_number:, message:)
    post(URL_PATHS[:send_sms], msg: message, to: recipient_number, sender_id: SENDER_ID)
  end

  def get_message_status_report(request_id)
    post("#{URL_PATHS[:request_report]}/#{request_id}")
  end

  def get_account_balance
    post(URL_PATHS[:user_balance])
  end

  private

  def api_key
    ENV["ALPHA_SMS_API_KEY"]
  end

  def post(path, body = {})
    uri = URI("https://#{HOST}#{path}")
    response = Net::HTTP.post_form(uri, **body, api_key: api_key)

    unless response.is_a?(Net::HTTPSuccess)
      raise Messaging::AlphaSms::Error.new(
        "API returned #{response.code} with #{response.body}"
      )
    end

    hsh_or_string(response.body)
  end

  def hsh_or_string(string)
    JSON.parse(string)
  rescue JSON::ParserError
    string.to_s
  end
end
