class Messaging::AlphaSms::Api
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
    post(URL_PATHS[:send_sms], {
      api_key: api_key,
      msg: message,
      to: recipient_number
    })
  end

  private

  def api_key
    ENV["ALPHA_SMS_API_KEY"]
  end

  def post(path, body = {})
    uri = URI("https://#{HOST}#{path}")
    response = Net::HTTP.post_form(uri, **body)

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
